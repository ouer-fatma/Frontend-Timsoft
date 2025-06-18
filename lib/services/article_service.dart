import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticleService {
  static const String _baseUrl = 'http://localhost:3000';


  static Future<List<String>> fetchFamilles() async {
    final response = await http.get(Uri.parse('$_baseUrl/articles/familles'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Échec de chargement des familles');
    }
  }
  
}
