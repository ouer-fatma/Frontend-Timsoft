import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; // for web localStorage
  import 'dart:convert'; 

class StorageService {
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage['token'] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      return html.window.localStorage['token'];
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    }
  }

  static Future<void> clearToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove('token');
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }

static Future<Map<String, dynamic>> getUserData() async {
  final token = await getToken();
  if (token == null) {
    throw Exception('Token non trouvé.');
  }

  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Token JWT invalide.');
  }

  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  return jsonDecode(payload);
}
}
