// ✅ client_screen.dart
import 'package:flutter/material.dart';
import 'package:project/services/user_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientsScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() => isLoading = true);
    try {
      clients = await _userService.getClients();
      filteredClients = clients;
    } catch (e) {
      print("❌ Erreur récupération clients: $e");
    }
    setState(() => isLoading = false);
  }

  void _search(String query) {
    setState(() {
      filteredClients = clients.where((c) {
        final nom = c['Nom']?.toLowerCase() ?? '';
        final prenom = c['Prenom']?.toLowerCase() ?? '';
        final email = c['Email']?.toLowerCase() ?? '';
        return nom.contains(query) || prenom.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Widget _buildCard(Map<String, dynamic> client) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.teal),
        title: Text(client['Nom'] ?? ''),
        subtitle: Text(client['Email'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des clients"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Rechercher un client...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) => _buildCard(filteredClients[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
