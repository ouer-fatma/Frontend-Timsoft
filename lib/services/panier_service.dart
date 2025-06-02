import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/config.dart';
import 'package:project/services/storage_service.dart';

class PanierService {
  final String baseUrl = '${AppConfig.baseUrl}/panier'; // ✅ safer for web too

  // 🔐 Extraire codeTiers à partir du token JWT
  Future<String> _getCodeTiersFromToken() async {
    final token = await StorageService.getToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      throw Exception("Token invalide ou expiré.");
    }

    final decoded = JwtDecoder.decode(token);
    final codeTiers = decoded['codeTiers'];
    if (codeTiers == null) {
      throw Exception("codeTiers non trouvé dans le token.");
    }

    return codeTiers;
  }

  // 🧺 Initialiser un panier pour un client donné
  Future<void> initPanier(String codeTiers) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codeTiers': codeTiers.trim().toUpperCase()}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = jsonDecode(response.body);
      print("✅ Panier initialisé ou existant : ${result['message']}");
    } else {
      throw Exception("Erreur à l'initialisation du panier : ${response.body}");
    }
  } catch (e) {
    throw Exception("Erreur réseau lors de l'initialisation du panier : $e");
  }
}


  // 📦 Récupérer les lignes du panier
  Future<List<Map<String, dynamic>>> getPanier({String? codeTiers}) async {
  final tiers = (codeTiers ?? await _getCodeTiersFromToken()).trim().toUpperCase();

  try {
    // Toujours initier le panier avant de le récupérer
    await initPanier(tiers);

    final response = await http.get(
      Uri.parse('$baseUrl/$tiers'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['panier']);
    } else if (response.statusCode == 404) {
      // Cas géré proprement : panier vide
      print("ℹ️ Aucun panier trouvé.");
      return [];
    } else {
      throw Exception("Erreur récupération du panier : ${response.body}");
    }
  } catch (e) {
    throw Exception("Erreur réseau lors de la récupération du panier : $e");
  }
}


  // ➕ Ajouter un article avec dimensions (basé sur GA_ARTICLE + GL_CODESDIM)
  Future<void> ajouterAuPanier({
  required String codeTiers,
  required String codeArticle,
  required double quantite,
  required String dim1Libelle,
  required String dim2Libelle,
  required String grilleDim1,
  required String grilleDim2,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ajouter'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "codeTiers": codeTiers.trim().toUpperCase(),
      "codeArticle": codeArticle.trim().toUpperCase(),
      "quantite": quantite,
      "dim1Libelle": dim1Libelle.trim().toUpperCase(),
      "dim2Libelle": dim2Libelle.trim().toUpperCase(),
      "grilleDim1": grilleDim1.trim().toUpperCase(),
      "grilleDim2": grilleDim2.trim().toUpperCase(),
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Erreur ajout au panier : ${response.body}");
  }
}



  // ❌ Supprimer une ligne du panier avec son code dimension combiné (GL_CODESDIM)
  Future<void> supprimerDuPanier(
    String codeTiers,
    String codeArticle, {
    required String codesdim, // ex: "00C-001"
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/retirer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeTiers': codeTiers,
        'codeArticle': codeArticle,
        'codesdim': codesdim,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression article : ${response.body}");
    }
  }
}
