import 'package:flutter/material.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/screens/auth/Login_screen.dart';
import 'package:project/widgets/login_side_panel.dart';

class RegisterSidePanel extends StatefulWidget {
  const RegisterSidePanel({super.key});

  @override
  State<RegisterSidePanel> createState() => _RegisterSidePanelState();
}

class _RegisterSidePanelState extends State<RegisterSidePanel> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? nomError;
  String? prenomError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\- ]+$');
    return nameRegex.hasMatch(name);
  }

  bool isStrongPassword(String password) {
    final pwRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return pwRegex.hasMatch(password);
  }

  final AuthService auth = AuthService();

  Future<void> _handleRegister() async {
    final nom = nomController.text.trim();
    final prenom = prenomController.text.trim();
    final email = emailController.text.trim();
    final motDePasse = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    setState(() {
      nomError = nom.isEmpty
          ? 'Ce champ est obligatoire.'
          : (!isValidName(nom)
              ? 'Le nom ne doit contenir que des lettres.'
              : null);
      prenomError = prenom.isEmpty
          ? 'Ce champ est obligatoire.'
          : (!isValidName(prenom)
              ? 'Le prénom ne doit contenir que des lettres.'
              : null);
      emailError = email.isEmpty
          ? 'Ce champ est obligatoire.'
          : (!isValidEmail(email)
              ? 'Saisissez une adresse e-mail valide (exemple : email@email.com).'
              : null);
      passwordError = motDePasse.isEmpty
          ? 'Ce champ est obligatoire.'
          : (!isStrongPassword(motDePasse)
              ? 'Tapez un mot de passe sûr : Au moins 8 caractères comprenant lettres majuscules, lettres minuscules et chiffres.'
              : null);
      confirmPasswordError = confirm.isEmpty
          ? 'Ce champ est obligatoire.'
          : (motDePasse != confirm
              ? 'Les mots de passe ne correspondent pas.'
              : null);
    });

    if ([nomError, prenomError, emailError, passwordError, confirmPasswordError]
        .any((e) => e != null)) {
      return;
    }

    final result = await auth.register(
      nom: nom,
      prenom: prenom,
      email: email,
      motDePasse: motDePasse,
    );

    if (result['status'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['body']['message'] ?? 'Inscription réussie')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['body']['message'] ?? 'Erreur inconnue')),
      );
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
        child: SingleChildScrollView(
          // ✅ Ajout ici
          child: Column(
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
                  'Créer un compte',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: const UnderlineInputBorder(),
                  errorText: nomError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon: nomError != null
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: const UnderlineInputBorder(),
                  errorText: prenomError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon: prenomError != null
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: const UnderlineInputBorder(),
                  errorText: emailError,
                  errorMaxLines:
                      3, // ✅ Affiche sur plusieurs lignes si nécessaire
                  errorStyle: const TextStyle(
                      color: Colors.red, fontSize: 13, height: 1.3),
                  prefixIcon: emailError != null
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                  labelStyle: TextStyle(
                    color: emailError != null ? Colors.red : null,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: emailError != null ? Colors.red : Colors.black),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: emailError != null ? Colors.red : Colors.grey),
                  ),
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
                  errorMaxLines: 3,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon: passwordError != null
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  labelStyle: TextStyle(
                    color: passwordError != null ? Colors.red : null,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color:
                            passwordError != null ? Colors.red : Colors.black),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color:
                            passwordError != null ? Colors.red : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: const UnderlineInputBorder(),
                  errorText: confirmPasswordError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon: confirmPasswordError != null
                      ? const Icon(Icons.error_outline, color: Colors.red)
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
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
                    foregroundColor: Colors.white, // ✅ Texte blanc
                  ),
                  onPressed: _handleRegister,
                  child: const Text("S'INSCRIRE"),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Ferme Register
                      showDialog(
                        context: context,
                        builder: (_) => const Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: LoginSidePanel(),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.black, // 👉 Ajuste selon ton fond
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
