import 'package:flutter/material.dart';
import 'admins_screen.dart';
import 'clients_screen.dart';
import 'magasiniers_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des utilisateurs")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            onPressed: () => navigateTo(context, const AdminsScreen()),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text("Administrateurs"),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => navigateTo(context, const MagasiniersScreen()),
            icon: const Icon(Icons.store),
            label: const Text("Magasiniers"),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => navigateTo(context, const ClientsScreen()),
            icon: const Icon(Icons.people),
            label: const Text("Clients"),
          ),
        ],
      ),
    );
  }
}
