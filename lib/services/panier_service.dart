import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/config.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/services/panier_local_service.dart';

class PanierService {
  final String baseUrl = '${AppConfig.baseUrl}/panier';

  Future<bool> _isGuest() async {
    final token = await StorageService.getToken();
    return token == null || JwtDecoder.isExpired(token);
  }

  Future<String> _getCodeTiersFromToken() async {
    final token = await StorageService.getToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      return 'GUEST';
    }
    return JwtDecoder.decode(token)['codeTiers'] ?? 'GUEST';
  }

  Future<void> initPanier(String codeTiers) async {
    if (await _isGuest()) return; // GUEST ne nécessite pas d'init
    final response = await http.post(
      Uri.parse('$baseUrl/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codeTiers': codeTiers.trim().toUpperCase()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur initialisation panier: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getPanier({String? codeTiers}) async {
    if (await _isGuest()) {
      print("👤 GUEST : récupération du panier local");
      return await PanierLocalService.getArticles();
    }

    final token = await StorageService.getToken();
    final tiers =
        (codeTiers ?? await _getCodeTiersFromToken()).trim().toUpperCase();

    final response = await http.get(
      Uri.parse('$baseUrl/$tiers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final panierList = data['panier'] as List;
      return panierList.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur récupération panier: ${response.body}');
    }
  }

  Future<void> ajouterAuPanier({
    String? codeTiers,
    required String codeArticle,
    required double quantite,
    required String dim1,
    required String dim2,
  }) async {
    final isGuest = await _isGuest();
    final tiers = (codeTiers?.trim().isNotEmpty == true)
        ? codeTiers!.trim().toUpperCase()
        : await _getCodeTiersFromToken();

    if (isGuest) {
      final article = {
        "GL_ARTICLE": codeArticle,
        "GA_LIBELLE": "Nom de l'article", // Remplace dynamiquement si dispo
        "GL_QTEFACT": quantite,
        "GA_PVTTC": 10.0, // Exemple de prix, à remplacer
        "dim1Libelle": dim1,
        "dim2Libelle": dim2,
        "GL_CODESDIM": "$dim1-$dim2",
        "TotalLigne": quantite * 10.0, // prix * quantité
      };

      return await PanierLocalService.addArticle(article);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/ajouter'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeTiers': tiers,
        'codeArticle': codeArticle.trim().toUpperCase(),
        'quantite': quantite,
        'dim1': dim1.trim().toUpperCase(),
        'dim2': dim2.trim().toUpperCase(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur ajout au panier: ${response.body}');
    }
  }

  Future<void> retirerDuPanier({
    required String codeTiers,
    required String codeArticle,
    required String codesdim,
  }) async {
    if (await _isGuest()) {
      return await PanierLocalService.removeArticle(codeArticle, codesdim);
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/retirer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeTiers': codeTiers.trim().toUpperCase(),
        'codeArticle': codeArticle.trim().toUpperCase(),
        'codesdim': codesdim.trim().toUpperCase(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression du panier: ${response.body}');
    }
  }

  Future<void> viderPanier() async {
    if (await _isGuest()) {
      return await PanierLocalService.clearPanier();
    }

    final codeTiers = await _getCodeTiersFromToken();
    final token = await StorageService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$codeTiers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression panier: ${response.body}');
    }
  }
}
