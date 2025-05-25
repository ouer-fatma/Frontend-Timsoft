import 'package:flutter/material.dart';
import 'package:project/services/storage_service.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu),
                label: const Text("Ouvrir le menu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB), // bleu
                  foregroundColor: Colors.white, // ✅ texte blanc
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await StorageService.clearToken(); // ❌ Supprime le token
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/', // redirige vers l'accueil/splash
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          )),
    );
  }
}
