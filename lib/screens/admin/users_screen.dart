import 'package:flutter/material.dart';
import 'package:project/services/user_service.dart';
import 'package:project/screens/admin/create_magasinier_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      users = await _userService.getAllUsers();
      filteredUsers = users;
      print("Utilisateurs récupérés : $users"); // 👈 AJOUT ICI
    } catch (e) {
      print("Erreur de récupération des utilisateurs: $e");
    }
    setState(() => isLoading = false);
  }

  void _searchUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['Nom'].toLowerCase();
        final email = user['Email'].toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showAddUserDialog() {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'client';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ajouter un utilisateur"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.createUser(
                  nom: nomController.text,
                  prenom: prenomController.text,
                  email: emailController.text,
                  motDePasse: passwordController.text,
                  role: selectedRole,
                );
                Navigator.pop(ctx);
                fetchUsers();
              } catch (e) {
                print("Erreur ajout utilisateur: $e");
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nomController = TextEditingController(text: user['Nom']);
    final prenomController = TextEditingController(text: user['Prenom']);
    final emailController = TextEditingController(text: user['Email']);
    final passwordController =
        TextEditingController(); // leave blank if unchanged
    String selectedRole = user['Role'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier l'utilisateur"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText:
                      'Nouveau mot de passe (laisser vide pour garder l\'ancien)',
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: const InputDecoration(labelText: 'Rôle'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.updateUser(
                  id: user['ID_Utilisateur'],
                  nom: nomController.text,
                  prenom: prenomController.text,
                  email: emailController.text,
                  role: selectedRole,
                  motDePasse: passwordController.text.isNotEmpty
                      ? passwordController.text
                      : null,
                );
                Navigator.pop(ctx);
                fetchUsers();
              } catch (e) {
                print("Erreur modification utilisateur: $e");
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet utilisateur ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _userService.deleteUser(id);
                fetchUsers();
              } catch (e) {
                print("Erreur suppression utilisateur: $e");
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Utilisateurs"),
      actions: [
        IconButton(
          icon: Icon(Icons.store_mall_directory),
          tooltip: "Créer un magasinier",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateMagasinierScreen()),
            ).then((_) => fetchUsers()); // recharger après ajout
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: "Rechercher un utilisateur...",
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
        if (!isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Utilisateurs trouvés : ${filteredUsers.length}",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(user['Nom']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${user['Email']}"),
                              Text("Rôle: ${user['Role']}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmDeleteUser(user['ID_Utilisateur']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF3B5BDB),
        child: const Icon(Icons.add),
      ),
    );
  }
  
}
