import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticleService {
  static const String _baseUrl = 'http://localhost:3000';

  /// Récupère l'arborescence complète des familles (classification hiérarchique)
  static Future<List<Map<String, dynamic>>>
      fetchFamillesClassification() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/articles/familles/classification'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Échec de chargement des familles');
    }
  }

  /// Récupère les sous-catégories (niveau 2) d’une famille (niveau 3)
  static Future<List<Map<String, String>>> fetchCategories(
      String famille) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/articles/famille/${Uri.encodeComponent(famille)}/categories'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, String>>.from(json.decode(response.body));
    } else {
      throw Exception('Échec de chargement des catégories');
    }
  }

  /// Récupère les articles associés à une catégorie (n’importe quel niveau)
  static Future<List<Map<String, dynamic>>> fetchArticlesByCategorie(
      String categorie) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/articles/categorie/${Uri.encodeComponent(categorie)}/articles'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Échec de chargement des articles');
    }
  }
}
