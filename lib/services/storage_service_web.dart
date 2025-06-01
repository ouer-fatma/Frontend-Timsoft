import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:convert';

class StorageService {
  static Future<void> saveToken(String token) async {
    html.window.localStorage['token'] = token;
  }

  static Future<String?> getToken() async {
    return html.window.localStorage['token'];
  }

  static Future<void> clearToken() async {
    html.window.localStorage.remove('token');
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final token = await getToken();
    if (token == null) throw Exception('Token non trouvé.');
    final parts = token.split('.');
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload);
  }
}
