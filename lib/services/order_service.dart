import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:project/config.dart';

class OrderService {
  String get baseUrl => '${AppConfig.baseUrl}/orders';

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes');
    }
  }

  Future<List<Map<String, dynamic>>> fetchClientOrders() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final payload = await StorageService.getUserData();
    final codeTiers = payload['codeTiers'];

    final response = await http.get(
      Uri.parse('$baseUrl/client/$codeTiers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes client');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes admin');
    }
  }

  Future<List<Map<String, dynamic>>> fetchReturns() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/retours'), // ✅ Bon chemin

      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Erreur chargement retours: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getOrderDetails({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/details/$nature/$souche/$numero/$indice'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération détails commande');
    }
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création commande');
    }
  }

  Future<void> updateOrder({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
    required Map<String, dynamic> updateData,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour commande');
    }
  }

  Future<void> deleteOrder({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression commande');
    }
  }
}
