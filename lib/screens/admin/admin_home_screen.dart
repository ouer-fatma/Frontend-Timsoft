import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project/services/Home_service.dart';

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
  PlatformFile? _selectedImage;

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

  void _showArticleDialog({Map<String, dynamic>? article}) {
    if (article == null) _selectedImage = null;
    final codeController =
        TextEditingController(text: article?['GA_CODEARTICLE']);
    final libelleController =
        TextEditingController(text: article?['GA_LIBELLE']);
    final pvhtController =
        TextEditingController(text: article?['GA_PVHT']?.toString());
    final pvttcController =
        TextEditingController(text: article?['GA_PVTTC']?.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(article == null ? "Ajouter un article" : "Modifier l'article"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Code Article"),
              ),
              TextField(
                controller: libelleController,
                decoration: const InputDecoration(labelText: "Libellé"),
              ),
              TextField(
                controller: pvhtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Prix HT"),
              ),
              TextField(
                controller: pvttcController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Prix TTC"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png'],
                    withData: true,
                  );

                  if (result != null && result.files.single.bytes != null) {
                    print(
                        "🟢 Image sélectionnée : ${result.files.single.name}");
                    print(
                        "📦 Bytes size: ${result.files.single.bytes!.length}");
                    setState(() {
                      _selectedImage = result.files.single;
                    });
                  } else {
                    print("❌ Aucun fichier sélectionné ou bytes null");
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text("Choisir une image"),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _selectedImage!.bytes != null
                      ? Image.memory(_selectedImage!.bytes!, height: 100)
                      : const Text("Aperçu indisponible"),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (article == null) {
                  await _articleService.createArticle(
                    code: codeController.text,
                    libelle: libelleController.text,
                    pvht: double.tryParse(pvhtController.text) ?? 0.0,
                    pvttc: double.tryParse(pvttcController.text) ?? 0.0,
                    image: _selectedImage,
                  );
                } else {
                  await _articleService.updateArticle(
                    id: article['GA_ARTICLE'],
                    libelle: libelleController.text,
                    pvht: double.tryParse(pvhtController.text) ?? 0.0,
                    pvttc: double.tryParse(pvttcController.text) ?? 0.0,
                    tenueStock: 'O',
                    image: _selectedImage,
                  );
                }

                await fetchArticles(); // ✅ Refresh first
                if (context.mounted) Navigator.pop(ctx); // ✅ Then close dialog
                _selectedImage = null;
              } catch (e) {
                print("Erreur : $e");
              }
            },
            child: Text(article == null ? "Ajouter" : "Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showArticleDialog(),
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
                      final imageUrl = article['GA_IMAGE_URL'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: imageUrl != null
                              ? Image.network(imageUrl,
                                  width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported),
                          title: Text(article['GA_LIBELLE'] ?? 'Sans libellé'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Code: ${article['GA_CODEARTICLE'] ?? '-'}"),
                              Text("Prix HT: ${article['GA_PVHT'] ?? '-'}"),
                              Text("Prix TTC: ${article['GA_PVTTC'] ?? '-'}"),
                              if (article['REMISE'] != null)
                                Text(
                                    "Remise: ${article['REMISE']['MLR_REMISE']}%"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () =>
                                    _showArticleDialog(article: article),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      article['GA_ARTICLE']);
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
