// lib/screens/client/user_profile_screen.dart
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userRole;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Utilisateur"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person, size: 100, color: Color(0xFF3B5BDB)),
            const SizedBox(height: 24),
            Text("Nom : $userName", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Email : $userEmail", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Rôle : $userRole", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
