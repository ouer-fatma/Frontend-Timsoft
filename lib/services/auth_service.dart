import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/config.dart';
import 'package:project/services/storage_service.dart';

class AuthService {
  String get baseUrl => '${AppConfig.baseUrl}/auth';

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
        'role': 'client',
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

    try {
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
        await StorageService.saveToken(responseData['token']);
      }

      return {
        'status': response.statusCode,
        'body': responseData,
      };
    } catch (e) {
      return {
        'status': 500,
        'body': {'message': 'Erreur réseau ou serveur.', 'error': e.toString()},
      };
    }
  }

  Future<void> logout() async {
    await StorageService.clearToken();
  }

  Future<String?> getToken() async {
    return await StorageService.getToken();
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
      await StorageService.saveToken(data['token']);
    }

    return {'status': response.statusCode, 'body': data};
  }

  Future<Map<String, dynamic>> googleLogin() async {
    if (kIsWeb) {
      try {
        final googleProvider = GoogleAuthProvider();

        final userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final idToken = await userCredential.user?.getIdToken();

        if (idToken == null) {
          return {
            'status': 400,
            'body': {'message': 'Token Google Web non récupéré.'}
          };
        }

        final response = await http.post(
          Uri.parse('$baseUrl/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': idToken}),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['token'] != null) {
          await StorageService.saveToken(data['token']);
        }

        return {'status': response.statusCode, 'body': data};
      } catch (e) {
        return {
          'status': 500,
          'body': {
            'message': 'Erreur Web Google Sign-In',
            'error': e.toString()
          },
        };
      }
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // ✅ Ne PAS définir clientId pour Web — il est automatiquement géré via Firebase
        clientId: kIsWeb
            ? null
            : '755445236888-44pjvgopqt8uvkpkfnt9ir78vph8hpb1.apps.googleusercontent.com',
      );

      await googleSignIn.signOut(); // force account selection
      final account = await googleSignIn.signIn();

      if (account == null) {
        return {
          'status': 400,
          'body': {'message': 'Connexion annulée'},
        };
      }

      final auth = await account.authentication;

      if (auth.idToken == null) {
        return {
          'status': 400,
          'body': {'message': 'ID Token introuvable.'},
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': auth.idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await StorageService.saveToken(data['token']);
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
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb
          ? null
          : '755445236888-d3g1dmodl74krp8j59c507i2r2gi11gq.apps.googleusercontent.com',
    );
    await googleSignIn.signOut();
  }
   
Future<bool> creerCompteCommercial({  // <- anciennement creerCompteMagasinierParDepot
  required String email,
  required String password,
  required int etablissement,

}) async {
  final url = Uri.parse('$baseUrl/creer-compte-commercial');
  final token = await StorageService.getToken();

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'email': email,
      'motDePasse': password,
      'etablissement': etablissement,
    }),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    final msg = jsonDecode(response.body)['message'];
    throw Exception(msg);
  }
}
Future<List<String>> fetchDepots() async {
  final url = Uri.parse('$baseUrl/depots');
  final token = await StorageService.getToken();

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data.map((d) => d['GCL_ETABLISSEMENT'].toString()));
  } else {
    throw Exception('Impossible de récupérer les dépôts');
  }
}

}