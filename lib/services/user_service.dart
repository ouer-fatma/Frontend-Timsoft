import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:project/config.dart';

class UserService {
  final String baseUrl = '${AppConfig.baseUrl}/users';

  Future<List<Map<String, dynamic>>> getAdmins() async {
    return _fetchUsers('$baseUrl/admins');
  }

  Future<List<Map<String, dynamic>>> getMagasiniers() async {
    return _fetchUsers('$baseUrl/magasiniers');
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    return _fetchUsers('$baseUrl/clients');
  }

  Future<List<Map<String, dynamic>>> _fetchUsers(String url) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.get(
      Uri.parse(url),
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
}
