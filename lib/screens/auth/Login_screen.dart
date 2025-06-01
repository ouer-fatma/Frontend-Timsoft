import 'package:flutter/material.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/auth/Create-account_screen.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/admin/admin_home_screen.dart';
import 'package:project/screens/magasinier/magasinier_home_screen.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/services/storage_service.dart';

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
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          // ✅ Background or branding area (left)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Image.asset('assets/background_brand.png', width: 500),
              ),
            ),
          ),

          // ✅ Right side login panel
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 400,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset('assets/logo.png', height: 50)),
                    const SizedBox(height: 30),
                    const Text(
                      'Connectez-vous',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () {
                          // 👉 login logic here
                        },
                        child: const Text('SE CONNECTER'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(child: Text('ou')),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // 👉 google login
                        },
                        child:
                            Image.asset('assets/google_icon.png', height: 40),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas de compte ? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateAccountScreen()),
                            );
                          },
                          child: const Text('Inscris-toi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
