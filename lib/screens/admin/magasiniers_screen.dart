import 'package:flutter/material.dart';
import 'package:project/services/user_service.dart';

class MagasiniersScreen extends StatefulWidget {
  const MagasiniersScreen({super.key});

  @override
  State<MagasiniersScreen> createState() => _MagasinierScreenState();
}

class _MagasinierScreenState extends State<MagasiniersScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> magasiniers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMagasiniers();
  }

  Future<void> fetchMagasiniers() async {
    setState(() => isLoading = true);
    try {
      magasiniers = await _userService.getMagasiniers();
    } catch (e) {
      print("Erreur récupération magasiniers: $e");
    }
    setState(() => isLoading = false);
  }

  Widget _buildCard(Map<String, dynamic> magasinier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(magasinier['Nom'] ?? 'Nom inconnu'),
        subtitle: Text(magasinier['Email'] ?? 'Email inconnu'),
        leading: const Icon(Icons.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des magasiniers"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: magasiniers.length,
              itemBuilder: (context, index) {
                return _buildCard(magasiniers[index]);
              },
            ),
    );
  }
}
