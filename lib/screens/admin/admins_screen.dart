import 'package:flutter/material.dart';
import 'package:project/services/user_service.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminsScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> admins = [];
  List<Map<String, dynamic>> filteredAdmins = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdmins();
  }

  Future<void> fetchAdmins() async {
    setState(() => isLoading = true);
    try {
      admins = await _userService.getAdmins();
      filteredAdmins = admins;
    } catch (e) {
      print("❌ Erreur récupération admins: $e");
    }
    setState(() => isLoading = false);
  }

  void _search(String query) {
    setState(() {
      filteredAdmins = admins.where((admin) {
        final nom = admin['Nom']?.toLowerCase() ?? '';
        final email = admin['Email']?.toLowerCase() ?? '';
        return nom.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading:
            const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
        title: Text(
          admin['Nom'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (admin['Email'] != null) Text("Email : ${admin['Email']}"),
            if (admin['Fonction'] != null)
              Text("Fonction : ${admin['Fonction']}"),
            if (admin['Groupe'] != null) Text("Groupe : ${admin['Groupe']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des administrateurs"),
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
                hintText: "Rechercher un admin...",
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
                    itemCount: filteredAdmins.length,
                    itemBuilder: (context, index) =>
                        _buildAdminCard(filteredAdmins[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
