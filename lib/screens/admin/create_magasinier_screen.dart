import 'package:flutter/material.dart';
import 'package:project/services/auth_service.dart';

class CreateMagasinierScreen extends StatefulWidget {
  @override
  _CreateMagasinierScreenState createState() => _CreateMagasinierScreenState();
}

class _CreateMagasinierScreenState extends State<CreateMagasinierScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> depots = [];
  String? selectedDepot;

  bool isLoading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadDepots();
  }

  void loadDepots() async {
    try {
      final authService = AuthService();
      final result = await authService.fetchDepots();
      setState(() => depots = result);
    } catch (e) {
      print("Erreur de chargement des dépôts: $e");
    }
  }

  void _createMagasinier() async {
    if (selectedDepot == null) {
      setState(() => message = 'Veuillez sélectionner un dépôt.');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final authService = AuthService();
      bool success = await authService.creerCompteCommercial(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        etablissement: int.parse(selectedDepot!),
      );

      if (success) {
        setState(() {
          message = 'Compte créé avec succès ✅';
          _emailController.clear();
          _passwordController.clear();
          selectedDepot = null;
        });
      }
    } catch (e) {
      setState(() => message = 'Erreur : ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer Magasinier")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedDepot,
              decoration: InputDecoration(labelText: "Sélectionner un dépôt"),
              items: depots.map((depot) {
                return DropdownMenuItem<String>(
                  value: depot,
                  child: Text('Dépôt $depot'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedDepot = val),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _createMagasinier,
                child: Text("Créer le compte"),
              ),
            SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: message.contains('succès') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
