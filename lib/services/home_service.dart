import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ArticleService {
  final String baseUrl = 'http://192.168.1.103:3000/articles';

  Future<List<Map<String, dynamic>>> fetchArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/search/$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<void> createArticle({
    required String code,
    required String libelle,
    required double pvht,
    required double pvttc,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'GA_ARTICLE': code,
        'GA_CODEARTICLE': code,
        'GA_LIBELLE': libelle,
        'GA_PVHT': pvht,
        'GA_PVTTC': pvttc,
        'GA_TENUESTOCK': 'O',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Erreur création: ${response.body}");
    }
  }

  Future<void> updateArticle({
    required String id,
    required String libelle,
    required double pvht,
    required double pvttc,
    required String tenueStock,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'GA_LIBELLE': libelle,
        'GA_PVHT': pvht,
        'GA_PVTTC': pvttc,
        'GA_TENUESTOCK': tenueStock,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur mise à jour: ${response.body}");
    }
  }

  Future<void> deleteArticle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression: ${response.body}");
    }
  }
}
