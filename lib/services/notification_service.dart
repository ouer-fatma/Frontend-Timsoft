import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _baseUrl = 'http://localhost:3000';

  static final List<Map<String, dynamic>> _localNotifs = [];

  static void notify(Map<String, dynamic> data) {
    final enriched = {
      ...data,
      'date': DateTime.now().toIso8601String(), // Ajout automatique de la date
    };
    _localNotifs.insert(0, enriched);
    for (final fn in _listeners) {
      fn();
    }
  }

  static List<Map<String, dynamic>> getLocalNotifications() => _localNotifs;

  static final List<VoidCallback> _listeners = [];

  static void registerListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  static void unregisterListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(
      String codeTiers) async {
    final response =
        await http.get(Uri.parse("$_baseUrl/notifications/$codeTiers"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur lors du chargement des notifications");
    }
  }
}
