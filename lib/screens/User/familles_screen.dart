import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/services/article_service.dart';
import 'article_detail_screen.dart';

class FamillesScreen extends StatefulWidget {
  @override
  _FamillesScreenState createState() => _FamillesScreenState();
}

class _FamillesScreenState extends State<FamillesScreen> {
  List<Map<String, dynamic>> familles = [];
  String? selectedFamilleCode;
  String? selectedSousFamilleCode;
  String? selectedSousFamilleLabel;
  List<Map<String, String>> sousFamilles = [];
  List<dynamic> articles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFamilles();
  }

  Future<void> loadFamilles() async {
    try {
      final data = await ArticleService.fetchFamillesClassification();
      setState(() {
        familles = data.map<Map<String, dynamic>>((famille) {
          return {
            'code': famille['code'],
            'label': famille['label'],
            'children': famille['children'] ?? []
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des familles : $e");
    }
  }

  Future<void> loadSousFamilles(String familleCode) async {
    setState(() {
      sousFamilles = [];
      selectedSousFamilleCode = null;
      selectedSousFamilleLabel = null;
      articles = [];
      isLoading = true;
    });

    try {
      // Trouve la famille sélectionnée (niveau 1)
      final selectedFamille = familles.firstWhere(
        (f) => f['code'] == familleCode,
        orElse: () => {},
      );

      // Accède aux catégories de niveau 2
      final List<dynamic> level2 = selectedFamille['children'] ?? [];

      final List<Map<String, String>> extracted = [];

      // Parcourt chaque catégorie niveau 2 et récupère ses enfants niveau 3
      for (final level2Item in level2) {
        final List<dynamic> level3 = level2Item['children'] ?? [];
        for (final level3Item in level3) {
          extracted.add({
            'code': level3Item['code'] ?? '',
            'label': level3Item['label'] ?? '',
          });
        }
      }

      setState(() {
        sousFamilles = extracted;
      });
    } catch (e) {
      print("Erreur chargement sous-familles : $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchArticles(String code, String label) async {
    setState(() {
      selectedSousFamilleCode = code;
      selectedSousFamilleLabel = label;
      articles = [];
      isLoading = true;
    });

    try {
      final url = 'http://localhost:3000/articles/categorie/$code/articles';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          articles = data;
        });
      } else {
        print("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur réseau: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = selectedSousFamilleLabel ??
        familles.firstWhere(
          (e) => e['code'] == selectedFamilleCode,
          orElse: () => {'label': selectedFamilleCode},
        )['label'];

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            currentTitle ?? '',
            style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w400),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
          leading: selectedSousFamilleCode != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      selectedSousFamilleCode = null;
                      articles = [];
                    });
                  },
                )
              : null,
        ),
        body: Column(
          children: [
            buildFamilleMenu(),
            if (isLoading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (selectedSousFamilleCode == null)
              Expanded(child: buildSousFamilles())
            else
              Expanded(child: buildArticles()),
          ],
        ),
      ),
    );
  }

  Widget buildFamilleMenu() {
    return Container(
      height: 50,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: familles.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final famille = familles[index];
          final isSelected = famille['code'] == selectedFamilleCode;
          return GestureDetector(
            onTap: () async {
              setState(() {
                selectedFamilleCode = famille['code'];
                articles = [];
              });
              await loadSousFamilles(famille['code']);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                famille['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSousFamilles() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 10),
      itemCount: sousFamilles.length,
      separatorBuilder: (_, __) => Divider(height: 0),
      itemBuilder: (_, index) {
        final sf = sousFamilles[index];
        return ListTile(
          title: Text(
            sf['label']!,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => fetchArticles(sf['code']!, sf['label']!),
        );
      },
    );
  }

  Widget buildArticles() {
    // Grouper les articles par GA_CODEARTICLE pour éviter les doublons
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final a in articles) {
      final code = a['GA_CODEARTICLE'];
      if (code != null && code is String && code.trim().isNotEmpty) {
        if (!grouped.containsKey(code)) {
          grouped[code] = a;
        }
      }
    }

    final uniqueArticles = grouped.values.toList();

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.65,
      ),
      itemCount: uniqueArticles.length,
      itemBuilder: (context, index) {
        final article = uniqueArticles[index];
        return GestureDetector(
          onTap: () {
            final codeArticle = article['GA_CODEARTICLE'];

            final variants = articles
                .where((a) =>
                    a['GA_CODEARTICLE'] == codeArticle &&
                    ((a['GA_CODEDIM1']?.toString().trim().isNotEmpty ??
                            false) ||
                        (a['GA_CODEDIM2']?.toString().trim().isNotEmpty ??
                            false)))
                .cast<Map<String, dynamic>>()
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(
                  article: article,
                  allVariants: variants,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: article['IMAGE'] != null
                        ? Image.memory(
                            base64Decode(article['IMAGE'].split(',').last),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (c, e, s) =>
                                Center(child: Icon(Icons.image_not_supported)),
                          )
                        : Center(child: Icon(Icons.image_not_supported)),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      article['GA_LIBELLE'] ?? 'Sans libellé',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                    child: Text(
                      "€${article['GA_PVTTC']}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 6),
                    child: Text(
                      "Stock : ${article['QUANTITE_TOTALE'] ?? 0}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
