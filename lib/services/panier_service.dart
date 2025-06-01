import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/config.dart'; // ✅ Replace dotenv usage

class PanierService {
  final String baseUrl = '${AppConfig.baseUrl}/panier'; // ✅ safer for web too

  /// 🔄 Initialize cart for the user (codeTiers)
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

  /// 🛒 Get panier items for the current user
  Future<List<Map<String, dynamic>>> getPanier() async {
    print("📡 [PanierService] getPanier() called");

    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final decoded = JwtDecoder.decode(token);
    final codeTiers = decoded['codeTiers'];

    print("🔍 codeTiers utilisé: $codeTiers");

    final response = await http.get(
      Uri.parse('$baseUrl/$codeTiers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ recommended for secured routes
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ [PanierService] Données reçues : $data");

      return List<Map<String, dynamic>>.from(data['panier']);
    } else {
      throw Exception("Erreur récupération panier: ${response.body}");
    }
  }

  /// ➕ Add an item to the user's panier
  Future<void> ajouterAuPanier({
    required String codeTiers,
    required String codeArticle,
    required double quantite,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/ajouter'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ recommended
      },
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
