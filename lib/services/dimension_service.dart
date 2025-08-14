import 'dart:convert';
import 'package:http/http.dart' as http;

class DimensionService {
  final String baseUrl = 'http://localhost:3000';

  /// Récupère la liste des dimensions disponibles pour un article
  Future<List<Map<String, String>>> getDimensions(String codeArticle) async {
    if (codeArticle.isEmpty) {
      throw Exception("Code article vide.");
    }

    final url = Uri.parse(
        '$baseUrl/articles/dimensions/${Uri.encodeComponent(codeArticle.trim())}');
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur chargement des dimensions : ${response.statusCode}");
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final raw = decoded['dimensions'] as List<dynamic>;
    return raw
        .where((e) => e is Map<String, dynamic>)
        .map<Map<String, String>>((e) => {
              'type': e['GDI_TYPEDIM'].toString(),
              'libelle': e['GDI_LIBELLE'].toString(),
            })
        .toList();
  }
}
