import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/main.dart';

import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/magasinier/magasinier_home_screen.dart';
import 'package:project/screens/auth/Login_screen.dart';
import 'package:project/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      await _initializeNotifications();
      _goToAuthRedirector(); // redirige après l'init
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      if (kIsWeb) {
        final sw = await html.window.navigator.serviceWorker?.ready;
        if (sw != null) {
          final token = await FirebaseMessaging.instance.getToken(
            vapidKey:
                'BIqXdbvEywygX6IVNP8X1d6tmm0B6pEF2QoeWC5Gw1Yc-H20BX1c5UvsRgj_ePC1tF1vHfGW4AhUduIhq2ktq0g',
          );

          print("🌐 Web FCM Token: $token");
          if (token != null) await sendTokenToBackend(token);
        }
      } else {
        await FirebaseMessaging.instance.subscribeToTopic('promotions');
      }
    } catch (e) {
      print("❌ Erreur init notifications: $e");
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/notifications/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );
      print('📬 Token envoyé au backend: ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur lors de l’envoi du token: $e');
    }
  }

  void _goToAuthRedirector() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthRedirector()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
