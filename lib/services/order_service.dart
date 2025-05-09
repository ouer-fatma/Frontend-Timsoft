import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<Map<String, dynamic>> getOrderDetails({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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
