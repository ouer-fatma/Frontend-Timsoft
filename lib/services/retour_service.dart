import 'dart:convert';
import 'package:http/http.dart' as http;

class RetourService {
  static const String baseUrl = 'http://localhost:3000/api'; // 🔧 adapte si nécessaire

  /// 📤 Envoie une demande de retour
  Future<void> createRetour({
    required String article,
    required int quantite,
    required String depot,
    required String utilisateur,
    required String modeRetour,
  }) async {
    final url = Uri.parse('$baseUrl/retours');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'article': article,
        'quantite': quantite,
        'depot': depot,
        'utilisateur': utilisateur,
        'modeRetour': modeRetour,
      }),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Erreur retour');
    }
  }

  /// 📥 Récupère les retours faits par un client
  Future<List<Map<String, dynamic>>> getRetoursByUtilisateur(String utilisateur) async {
    final url = Uri.parse('$baseUrl/retours/utilisateur/$utilisateur');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Erreur lors du chargement des retours");
    }
  }
}
