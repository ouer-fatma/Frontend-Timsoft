import 'package:flutter/material.dart';
import 'package:project/services/Home_service.dart';

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArticleService _articleService = ArticleService();

  final TextEditingController codeController = TextEditingController();
  final TextEditingController libelleController = TextEditingController();
  final TextEditingController pvhtController = TextEditingController();
  final TextEditingController pvttcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un article"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code article'),
                validator: (value) =>
                    value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: libelleController,
                decoration: const InputDecoration(labelText: 'Libellé'),
                validator: (value) =>
                    value!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: pvhtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix HT'),
              ),
              TextFormField(
                controller: pvttcController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix TTC'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _articleService.createArticle(
                      code: codeController.text,
                      libelle: libelleController.text,
                      pvht: double.tryParse(pvhtController.text) ?? 0.0,
                      pvttc: double.tryParse(pvttcController.text) ?? 0.0,
                    );
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB),
                ),
                child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
