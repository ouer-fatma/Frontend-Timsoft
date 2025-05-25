import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/magasinier/magasinier_home_screen.dart';
import 'package:project/screens/auth/Create-account_screen.dart';
import 'package:project/widgets/register_side_panel.dart';

class LoginSidePanel extends StatefulWidget {
  const LoginSidePanel({super.key});

  @override
  State<LoginSidePanel> createState() => _LoginSidePanelState();
}

class _LoginSidePanelState extends State<LoginSidePanel> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService auth = AuthService();
  bool obscurePassword = true;
  bool isLoading = false;
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  String? emailError;
  String? passwordError;
  String? generalError; // Message d’erreur général (ex: mauvais identifiants)

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
      generalError = null;
    });

    try {
      if (email.isEmpty || !isValidEmail(email)) {
        setState(() {
          emailError = email.isEmpty ? 'Champ obligatoire' : 'Email invalide';
        });
      }

      if (password.isEmpty) {
        setState(() {
          passwordError = 'Champ obligatoire';
        });
      }

      if (emailError != null || passwordError != null) return;

      final result = await auth.login(email: email, motDePasse: password);

      // ✅ Vérifie si le login a échoué (même sans token)
      if (result['status'] != 200 || result['body']['token'] == null) {
        setState(() {
          generalError = result['body']['message'] ?? 'Erreur inconnue.';
        });
        return;
      }

      final token = result['body']['token'];
      await StorageService.clearToken();
      await StorageService.saveToken(token);

      final decoded = JwtDecoder.decode(token);
      final String role = decoded['role'];
      final String nom = decoded['nom'];

      Widget screen;
      if (role == 'admin') {
        screen = const AdminDashboardScreen();
      } else if (role == 'personnel_magasin') {
        screen = const MagasinierHomeScreen();
      } else {
        screen = HomeScreen(
          userNom: nom,
          userEmail: decoded['email'],
          userRole: role,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => screen));
    } catch (e) {
      setState(() {
        generalError = 'Erreur : ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      final result = await auth.googleLogin();

      if (result['status'] == 200 && result['body']['token'] != null) {
        final token = result['body']['token'];
        await StorageService.clearToken();
        await StorageService.saveToken(token);

        final decoded = JwtDecoder.decode(token);
        final String role = decoded['role'];
        final String nom = decoded['nom'];

        Widget screen;
        if (role == 'admin') {
          screen = const AdminDashboardScreen();
        } else if (role == 'personnel_magasin') {
          screen = const MagasinierHomeScreen();
        } else {
          screen = HomeScreen(
            userNom: nom,
            userEmail: decoded['email'],
            userRole: role,
          );
        }

        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => screen));
      } else {
        setState(() {
          generalError = result['body']['message'] ?? 'Erreur Google Sign-In.';
        });
      }
    } catch (e) {
      setState(() {
        generalError = 'Erreur : ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 400,
        height: double.infinity,
        padding: const EdgeInsets.all(32),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator()) // ✅ Loader visible
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Connectez-vous',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: const UnderlineInputBorder(),
                      errorText: emailError,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: emailError != null
                          ? const Icon(Icons.error_outline, color: Colors.red)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const UnderlineInputBorder(),
                      errorText: passwordError,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: passwordError != null
                          ? const Icon(Icons.error_outline, color: Colors.red)
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  if (generalError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      generalError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // action
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color:
                              Colors.black, // 👈 ou Colors.white si fond noir
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white, // ✅ force le texte blanc
                      ),
                      onPressed: _handleLogin,
                      child: const Text('SE CONNECTER'),
                    ),
                  ),

                  const SizedBox(height: 16),

// 👉 Bouton Google Sign-In
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _handleGoogleLogin,
                    icon: Image.asset('assets/google_icon.png', height: 20),
                    label: const Text("Continuer avec Google"),
                  ),

                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas de compte ?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => const Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: RegisterSidePanel(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Inscris-toi',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
