import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final String baseUrl = 'http://127.0.0.1:3000/auth';
  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
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

  Future<Map<String, dynamic>> googleLoginWithToken(String idToken) async {
    final url = Uri.parse('$baseUrl/google');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
    }

    return {'status': response.statusCode, 'body': data};
  }

  Future<Map<String, dynamic>> googleLogin() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId:
            '755445236888-d3g1dmodl74krp8j59c507i2r2gi11gq.apps.googleusercontent.com', // ✅ Web Client ID
      );

      await _googleSignIn.signOut(); // 👈 Forces account re-selection
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return {
          'status': 400,
          'body': {'message': 'Connexion annulée par l\'utilisateur'}
        };
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      // ✅ Print token to copy and test in Postman
      print("📥 Google ID Token: ${auth.idToken}");
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

  Future<void> googleSignOut() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId:
          '755445236888-d3g1dmodl74krp8j59c507i2r2gi11gq.apps.googleusercontent.com',
    );
    await _googleSignIn.signOut();
  }
}
