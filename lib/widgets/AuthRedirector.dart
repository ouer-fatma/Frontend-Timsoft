import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/magasinier/magasinier_home_screen.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';


class AuthRedirector extends StatelessWidget {
  const AuthRedirector({super.key});

  Future<Widget> _decideStartScreen() async {
    final token = await StorageService.getToken();

    if (token == null || JwtDecoder.isExpired(token)) {
      return const WelcomeScreen(); // 🔁 Pas connecté
    }

    final decoded = JwtDecoder.decode(token);
    final String role = decoded['role'] ?? 'client';
    final String email = decoded['email'] ?? '';
    final String nom = decoded['nom'] ?? decoded['T_LIBELLE'] ?? email;

    if (role == 'admin') {
      return const AdminDashboardScreen();
    } else if (role == 'personnel_magasin') {
      return const MagasinierHomeScreen();
    } else {
      return HomeScreen(userNom: nom, userEmail: email, userRole: role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decideStartScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data,
        );
      },
    );
  }
}
