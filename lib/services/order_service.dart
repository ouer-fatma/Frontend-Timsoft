import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  final String baseUrl = 'http://127.0.0.1:3000/orders';

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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

  // ✅ CLIENT: Récupérer ses propres commandes
  Future<List<Map<String, dynamic>>> fetchClientOrders() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final payload = await StorageService.getUserData();
    final codeTiers = payload['codeTiers'];

    final response = await http.get(
      Uri.parse(
          '$baseUrl/client/$codeTiers'), // 👈 crée cette route côté backend si elle n'existe pas
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes client');
    }
  }

  // ✅ ADMIN: Récupérer toutes les commandes
  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

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
      Uri.parse('http://localhost:3000/returns'),
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

    final url = '$baseUrl/details/$nature/$souche/$numero/$indice';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération détails commande');
    }
  }

  // ✅ Création commande
  Future<void> createOrder(Map<String, dynamic> orderData) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

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

  // ✅ Mise à jour commande (optionnel)
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression commande');
    }
  }

  // You can add createOrder(), updateOrder() later
}
