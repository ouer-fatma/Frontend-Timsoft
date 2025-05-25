import 'package:flutter/material.dart';
import 'package:project/services/Home_service.dart';

class EditArticleScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  const EditArticleScreen({super.key, required this.article});

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ArticleService _articleService = ArticleService();

  late TextEditingController libelleController;
  late TextEditingController pvhtController;
  late TextEditingController pvttcController;

  @override
  void initState() {
    super.initState();
    libelleController =
        TextEditingController(text: widget.article['GA_LIBELLE']);
    pvhtController =
        TextEditingController(text: widget.article['GA_PVHT'].toString());
    pvttcController =
        TextEditingController(text: widget.article['GA_PVTTC'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier l'article"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Code: ${widget.article['GA_CODEARTICLE']}"),
              const SizedBox(height: 10),
              TextFormField(
                controller: libelleController,
                decoration: const InputDecoration(labelText: 'Libellé'),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
                    await _articleService.updateArticle(
                      id: widget.article['GA_ARTICLE'],
                      libelle: libelleController.text,
                      pvht: double.tryParse(pvhtController.text) ?? 0.0,
                      pvttc: double.tryParse(pvttcController.text) ?? 0.0,
                      tenueStock: 'O', // ✅ this fixes the error
                    );
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB),
                ),
                child: const Text("Mettre à jour",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
