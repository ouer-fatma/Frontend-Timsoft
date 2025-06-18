import 'dart:convert';
import 'package:http/http.dart' as http;

class DimensionService {
  final String baseUrl = 'http://localhost:3000';


  Future<List<Map<String, String>>> getDimensions(String codeArticle) async {
    if (codeArticle.isEmpty) {
      throw Exception("Code article vide.");
    }

    final url = Uri.parse('$baseUrl/articles/dimensions/${codeArticle.trim()}');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur HTTP lors du chargement des dimensions : ${response.statusCode}");
    }

    final decoded = json.decode(response.body);
    if (decoded == null || decoded is! Map || !decoded.containsKey('dimensions')) {
      throw Exception("Réponse invalide du serveur.");
    }

    final List<dynamic> rawDimensions = decoded['dimensions'];

    // Vérification de structure + transformation
    return rawDimensions
        .where((e) => e is Map && e['type'] != null && e['libelle'] != null)
        .map<Map<String, String>>((e) => {
              "type": e['type'].toString(),
              "libelle": e['libelle'].toString(),
            })
        .toList();
  }
}
