import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:project/config.dart';

class UserService {
  final String baseUrl = '${AppConfig.baseUrl}/users';

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la récupération des utilisateurs');
    }
  }

  Future<void> createUser({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'motDePasse': motDePasse,
        'role': role,
      }),
    );

    if (response.statusCode != 201) {
      final body = _tryParseBody(response.body);
      throw Exception(body['message'] ?? 'Erreur création utilisateur');
    }
  }

  Future<void> updateUser({
    required int id,
    required String nom,
    required String prenom,
    required String email,
    required String role,
    String? motDePasse,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final body = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
    };

    if (motDePasse != null && motDePasse.trim().isNotEmpty) {
      body['motDePasse'] = motDePasse;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur mise à jour utilisateur');
    }
  }

  Future<void> deleteUser(int id) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l’utilisateur');
    }
  }

  Map<String, dynamic> _tryParseBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'message': body};
    }
  }
}
