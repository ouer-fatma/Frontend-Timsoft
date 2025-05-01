import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final String baseUrl = 'http://192.168.1.103:3000/auth';

  Future<Map<String, dynamic>> register({
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'email': email,
        'motDePasse': motDePasse,
      }),
    );

    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String motDePasse,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'motDePasse': motDePasse,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['token'] != null) {
      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
    }

    return {
      'status': response.statusCode,
      'body': responseData,
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> googleLogin() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // 🔥 This is CRITICAL: Use your Web Client ID here!
        serverClientId:
            '755445236888-t23s8ruotiugblkiu3iju1pmgqs8gbci.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return {
          'status': 400,
          'body': {'message': 'Annulé par l\'utilisateur'}
        };
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      print("📱 Google ID Token: ${auth.idToken}");

      final url = Uri.parse('$baseUrl/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': auth.idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }

      return {'status': response.statusCode, 'body': data};
    } catch (e) {
      return {
        'status': 500,
        'body': {'message': 'Erreur Google Sign-In', 'error': e.toString()},
      };
    }
  }
}
