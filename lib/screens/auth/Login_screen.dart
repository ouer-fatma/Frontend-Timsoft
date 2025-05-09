import 'package:flutter/material.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/auth/Create-account_screen.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/admin/admin_home_screen.dart'; // ✅ IMPORT THIS

import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService auth = AuthService();
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE3F0FF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 160),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  style: const TextStyle(
                      color: Colors.black), // 👈 Texte saisi en noir
                  decoration: InputDecoration(
                    hintText: "E-mail",
                    hintStyle:
                        const TextStyle(color: Colors.grey), // 👈 Hint en gris
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F5),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(
                      color: Colors.black), // ✅ texte saisi en noir
                  decoration: InputDecoration(
                    hintText: "Mot de passe",
                    hintStyle:
                        const TextStyle(color: Colors.grey), // ✅ hint en gris
                    prefixIcon: const Icon(Icons.lock,
                        color: Colors.grey), // ✅ icône grise
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F5),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Tu as oublié ton mot de passe ?",
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Veuillez remplir tous les champs.')),
                        );
                        return;
                      }

                      final result = await auth.login(
                        email: email,
                        motDePasse: password,
                      );

                      if (result['status'] == 200) {
                        final token = await auth.getToken();
                        if (token != null) {
                          Map<String, dynamic> decoded =
                              JwtDecoder.decode(token);
                          String role = decoded['role'];
                          String nom = decoded['nom']; // 👈 récupère le nom ici

                          if (role == 'admin') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen()),
                            );
                          } else if (role == 'client') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomeScreen(
                                  userNom: nom,
                                  userEmail: decoded['email'],
                                  userRole: role,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Rôle inconnu : $role")),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result['body']['message'] ??
                                  'Erreur inconnue')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("SE CONNECTER",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("ou se connecter avec",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await auth.googleLogin();

                        if (result['status'] == 200) {
                          final token = await auth.getToken();
                          if (token != null) {
                            Map<String, dynamic> decoded =
                                JwtDecoder.decode(token);
                            String role = decoded['role'];
                            String nom = decoded['nom'];

                            if (role == 'admin') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminHomeScreen()),
                              );
                            } else if (role == 'client') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomeScreen(
                                    userNom: nom,
                                    userEmail: decoded['email'],
                                    userRole: role,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Rôle inconnu : $role")),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(result['body']['message'] ??
                                    'Erreur inconnue')),
                          );
                        }
                      },
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset('assets/google_icon.png'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Tu n'as pas de compte ? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateAccountScreen()),
                        );
                      },
                      child: const Text(
                        "Inscris-toi",
                        style: TextStyle(
                            color: Color(0xFF3B5BDB),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
