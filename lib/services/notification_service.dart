import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _baseUrl = 'http://localhost:3000';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final List<Map<String, dynamic>> _localNotifs = [];
  static final List<VoidCallback> _listeners = [];

  /// Initialisation complète du service FCM + abonnement
  static Future<void> initializeFCM() async {
    // 🔐 Demander la permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔔 Abonnement au topic utilisé par le backend
    await _messaging.subscribeToTopic('promotions');

    // 📬 Réception en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = {
        'title': message.notification?.title ?? 'Nouvelle notification',
        'message': message.notification?.body ?? '',
        'date': DateTime.now().toIso8601String(),
      };
      _localNotifs.insert(0, notification);
      _listeners.forEach((fn) => fn());
    });

    // 🚀 Notification cliquée depuis background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notification = {
        'title': message.notification?.title ?? 'Notification ouverte',
        'message': message.notification?.body ?? '',
        'date': DateTime.now().toIso8601String(),
      };
      _localNotifs.insert(0, notification);
      _listeners.forEach((fn) => fn());
    });

    // 💤 Notification à l’ouverture si l'app était terminée
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final notification = {
        'title': initialMessage.notification?.title ?? 'Notification reçue',
        'message': initialMessage.notification?.body ?? '',
        'date': DateTime.now().toIso8601String(),
      };
      _localNotifs.insert(0, notification);
      _listeners.forEach((fn) => fn());
    }
  }

  /// Notifications locales internes
  static void notify(Map<String, dynamic> data) {
    final enriched = {
      ...data,
      'date': DateTime.now().toIso8601String(),
    };
    _localNotifs.insert(0, enriched);
    _listeners.forEach((fn) => fn());
  }

  /// Accès aux notifs locales
  static List<Map<String, dynamic>> getLocalNotifications() => _localNotifs;

  /// Gestion d’écoute
  static void registerListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  static void unregisterListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  /// Notifications stockées côté backend
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

  static Future<List<Map<String, dynamic>>> fetchAllNotifications() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:3000/notifications/all"),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN', // si jamais tu utilises des tokens plus tard
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Erreur fetchAllNotifications: $e");
      rethrow;
    }
  }

  
}
