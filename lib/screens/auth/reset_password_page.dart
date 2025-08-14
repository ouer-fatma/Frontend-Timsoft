import 'package:flutter/material.dart';
import 'package:project/services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final auth = AuthService();
    final res = await auth.resetPassword(
      token: widget.token,
      nouveauMotDePasse: _passwordController.text,
    );

    setState(() {
      _loading = false;
      _message = res['body']['message'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Définissez un nouveau mot de passe'),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Au moins 6 caractères',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Valider'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 20),
                Text(_message!, style: const TextStyle(color: Colors.green)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
