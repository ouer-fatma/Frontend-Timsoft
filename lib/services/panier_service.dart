import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class PanierService {
  final String baseUrl = 'http://localhost:3000/panier';

  Future<void> initPanier(String codeTiers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codeTiers': codeTiers}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erreur init panier: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getPanier() async {
    print("📡 [PanierService] getPanier() called");
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final decoded = JwtDecoder.decode(token);
    final codeTiers = decoded['codeTiers'];

    print("🔍 codeTiers utilisé: $codeTiers");

    final response = await http.get(
      Uri.parse('$baseUrl/$codeTiers'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ [PanierService] Données reçues : $data");

      return List<Map<String, dynamic>>.from(data['panier']);
    } else {
      throw Exception("Erreur récupération panier: ${response.body}");
    }
  }

  Future<void> ajouterAuPanier({
    required String codeTiers,
    required String codeArticle,
    required double quantite,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ajouter'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeTiers': codeTiers,
        'codeArticle': codeArticle,
        'quantite': quantite,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erreur ajout panier: ${response.body}");
    }
  }
}
