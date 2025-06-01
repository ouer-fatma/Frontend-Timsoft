import 'package:flutter/material.dart';
import 'package:project/screens/magasinier/magasinier_orders_screen.dart';
import 'package:project/screens/magasinier/magasinier_order_detail_screen.dart';
import 'package:project/screens/magasinier/magasinier_returns_screen.dart';

class MagasinierHomeScreen extends StatelessWidget {
  const MagasinierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Magasinier"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
            context,
            icon: Icons.assignment,
            title: "Commandes à traiter",
            subtitle: "Voir et préparer les commandes",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MagasinierOrdersScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTile(
            context,
            icon: Icons.assignment_return,
            title: "Retours",
            subtitle: "Gérer les retours clients",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MagasinierReturnsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          // Ajoute d'autres accès ici (ex: inventaire)
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
