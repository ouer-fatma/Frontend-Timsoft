import 'package:flutter/material.dart';
import 'package:project/screens/magasinier/TransfertListScreen%20.dart';
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
          ListTile(
  leading: const Icon(Icons.compare_arrows, color: Colors.teal),
  title: const Text("Transferts", style: TextStyle(fontWeight: FontWeight.bold)),
  subtitle: const Text("Voir les demandes de transfert"),
  tileColor: Colors.grey.shade100,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransfertListScreen()),
    );
  },
),
const SizedBox(height: 12),

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
