import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/auth/Login_screen.dart';
import 'package:project/screens/admin/admin_home_screen.dart';
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/screens/User/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final token = await StorageService.getToken();

    if (!mounted) return; // ✅ Only works inside State class

    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final decodedToken = JwtDecoder.decode(token);
      final role = decodedToken['role'];
      final nom = decodedToken['nom'];
      final email = decodedToken['email'];

      if (role == 'admin') {
        Navigator.pushReplacement(
          context, // ✅ context available here
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userNom: nom,
              userEmail: email,
              userRole: role,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
