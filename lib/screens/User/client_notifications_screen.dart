import 'package:flutter/material.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? codeTiers;

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // 🔄 Écoute les nouvelles notifications locales (non sauvegardées en DB)
    NotificationService.registerListener(_onNewNotification);
  }

  @override
  void dispose() {
    NotificationService.unregisterListener(_onNewNotification);
    super.dispose();
  }

  void _onNewNotification() {
    setState(() {
      final nouvelles = NotificationService.getLocalNotifications();
      for (var notif in nouvelles) {
        if (!notifications.contains(notif)) {
          notifications.insert(0, notif);
        }
      }
    });
  }

  Future<void> _loadNotifications() async {
    final token = await StorageService.getToken();
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      codeTiers = decoded['codeTiers'];

      try {
        final fetched = await NotificationService.fetchAllNotifications();

        final local = NotificationService.getLocalNotifications();

        setState(() {
          // Combine local + distantes
          notifications = [...local, ...fetched];
          isLoading = false;
        });
      } catch (e) {
        print("Erreur fetch notif: $e");
        setState(() {
          notifications = NotificationService.getLocalNotifications();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("Aucune notification pour l’instant."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(notif['title'] ?? 'Notification'),
                        subtitle: Text(notif['message'] ?? ''),
                        trailing: Text(
                          notif['date'] != null
                              ? notif['date'].toString().substring(0, 10)
                              : '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
