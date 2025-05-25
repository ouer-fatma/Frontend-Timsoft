// ✅ Importations essentielles
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'article_detail_screen.dart'; // <-- Assure-toi que ce chemin est correct

class FamillesScreen extends StatefulWidget {
  @override
  _FamillesScreenState createState() => _FamillesScreenState();
}

class _FamillesScreenState extends State<FamillesScreen> {
  final List<String> allowedFamilles = ['FEM', 'HOM', 'FIL', 'GAR'];

  final Map<String, String> familleLabels = {
    'FEM': 'FEMME',
    'HOM': 'HOMME',
    'FIL': 'FILLE',
    'GAR': 'GARÇON',
  };

  final Map<String, String> categorieLabels = {
    'ACC': 'Accessoires',
    'ACW': 'Manteaux',
    'BTS': 'Baskets',
    'BUD': 'Bodys',
    'BWE': 'Bijoux & Écharpes',
    'CHE': 'Chemises',
    'CHEMISES': 'Chemises',
    'COC': 'Cocooning',
    'COM': 'Combinaisons',
    'DEN': 'Denim',
    'ENS': 'Ensembles',
    'GIL': 'Gilets',
    'HOM': 'Home',
    'JOG': 'Jogging',
    'JNS': 'Jeans',
    'JUP': 'Jupes',
    'KNW': 'Maille / Knitwear',
    'LGG': 'Leggings',
    'OTW': 'Vestes & Manteaux',
    'PAN': 'Pantalons',
    'PLO': 'Polos',
    'PNT': 'Pantalons',
    'PUL': 'Pulls',
    'ROB': 'Robes',
    'ROBES': 'Robes',
    'SBP': 'Sacs & Bananes',
    'SHO': 'Chaussures',
    'SHS': 'Sandales / Shoes',
    'SWJ': 'Sweats & Joggers',
    'SWT': 'Sweats',
    'TOP': 'Tops',
    'TSH': 'T-shirts',
    'TOPS & T-SHIRTS': 'Tops & T-shirts',
    'VST': 'Vestes',
  };

  List<String> familles = [];
  List<String> categories = [];
  List<dynamic> articles = [];

  String? selectedFamille = 'FEM';
  String? selectedCategorie;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFamilles();
  }

  Future<void> fetchFamilles() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/articles/familles'));
      if (response.statusCode == 200) {
        final raw = List<String>.from(json.decode(response.body));
        familles = raw.where((f) => allowedFamilles.contains(f.trim())).toList();
        if (selectedFamille != null) fetchCategories(selectedFamille!);
      }
    } catch (e) {
      print("Erreur fetch familles: $e");
    }
  }

  Future<void> fetchCategories(String famille) async {
    setState(() {
      selectedFamille = famille;
      categories = [];
      articles = [];
      selectedCategorie = null;
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/articles/categories/$famille'));
      if (response.statusCode == 200) {
        categories = List<String>.from(json.decode(response.body));
      }
    } catch (e) {
      print("Erreur fetch catégories: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchArticles(String categorie) async {
    setState(() {
      selectedCategorie = categorie;
      articles = [];
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/articles/categorie/$categorie'));
      if (response.statusCode == 200) {
        articles = json.decode(response.body);
      }
    } catch (e) {
      print("Erreur fetch articles: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = selectedCategorie != null
        ? (categorieLabels[selectedCategorie!] ?? selectedCategorie!)
        : (familleLabels[selectedFamille!] ?? selectedFamille!);

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
            currentTitle,
            style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w400),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
          leading: selectedCategorie != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      selectedCategorie = null;
                      articles = [];
                    });
                  },
                )
              : null,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFamilleMenu(),
            if (isLoading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (selectedCategorie == null)
              Expanded(child: buildCategories())
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
          final isSelected = selectedFamille == famille;
          return GestureDetector(
            onTap: () => fetchCategories(famille),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                familleLabels[famille] ?? famille,
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

  Widget buildCategories() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 10),
      itemCount: categories.length,
      separatorBuilder: (_, __) => Divider(height: 0),
      itemBuilder: (_, index) {
        final catCode = categories[index];
        return ListTile(
          title: Text(
            categorieLabels[catCode] ?? catCode,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => fetchArticles(catCode),
        );
      },
    );
  }

  Widget buildArticles() {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.65,
      ),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(article: article),
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
                    child: Image.network(
                      article['GA_IMAGE_URL'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      article['GA_LIBELLE'] ?? 'Sans libellé',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8),
                    child: Text(
                      "€${article['GA_PVTTC']}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
