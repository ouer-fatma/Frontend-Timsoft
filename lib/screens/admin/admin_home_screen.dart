import 'package:flutter/material.dart';
import 'package:project/services/Home_service.dart';
import 'add_article_screen.dart';
import 'edit_article_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<Map<String, dynamic>> articles = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ArticleService _articleService = ArticleService();

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    setState(() => isLoading = true);
    try {
      articles = await _articleService.fetchArticles();
    } catch (e) {
      print("Erreur: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> searchArticles(String query) async {
    setState(() => isLoading = true);
    try {
      if (query.trim().isEmpty) {
        await fetchArticles();
      } else {
        articles = await _articleService.searchArticles(query);
      }
    } catch (e) {
      print("Erreur recherche: $e");
    }
    setState(() => isLoading = false);
  }

  void _showDeleteConfirmation(String gaArticle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet article ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _articleService.deleteArticle(gaArticle);
              fetchArticles();
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Articles"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddArticleScreen()),
          );
          if (added == true) {
            fetchArticles();
          }
        },
        backgroundColor: const Color(0xFF3B5BDB),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => searchArticles(value),
              decoration: InputDecoration(
                hintText: "Rechercher un article...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(article['GA_LIBELLE'] ?? 'Sans libellé'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Code: ${article['GA_CODEARTICLE'] ?? '-'}"),
                              Text("Prix HT: ${article['GA_PVHT'] ?? '-'}"),
                              Text("Prix TTC: ${article['GA_PVTTC'] ?? '-'}"),
                              if (article['REMISE'] != null)
                                Text("Remise: ${article['REMISE']['MLR_REMISE']}%"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditArticleScreen(article: article),
                                    ),
                                  );
                                  if (updated == true) {
                                    fetchArticles();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(article['GA_ARTICLE']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
