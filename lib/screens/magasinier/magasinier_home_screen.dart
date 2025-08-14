import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:project/screens/magasinier/TransfertListScreen%20.dart';
import 'package:project/screens/magasinier/magasinier_orders_screen.dart';
import 'package:project/screens/magasinier/magasinier_reservations_screen.dart';
import 'package:project/screens/magasinier/magasinier_returns_screen.dart';
import 'package:project/services/storage_service.dart';

class MagasinierHomeScreen extends StatefulWidget {
  const MagasinierHomeScreen({super.key});

  @override
  State<MagasinierHomeScreen> createState() => _MagasinierHomeScreenState();
}

class _MagasinierHomeScreenState extends State<MagasinierHomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await StorageService.getToken();

    if (!mounted) return;

    // 🔒 Redirige si pas de token
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    // 🔐 Vérifie le rôle
    final userData = await StorageService.getUserData();
    if (userData == null || userData['role'] != 'personnel_magasin') {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Magasinier"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () async {
              await StorageService.clearToken();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
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
          _buildTile(
            icon: Icons.compare_arrows,
            title: "Transferts",
            subtitle: "Voir les demandes de transfert",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransfertListScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTile(
            icon: Icons.store_mall_directory,
            title: "Réservations",
            subtitle: "Commandes à retirer en dépôt",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MagasinierReservationsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
