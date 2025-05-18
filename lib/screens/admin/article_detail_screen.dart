import 'package:flutter/material.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article['GA_LIBELLE'] ?? 'Détail Article'),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replace with article image if available
            Image.asset(
              'assets/articles/chemise.jpg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              article['GA_LIBELLE'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Code: ${article['GA_CODEARTICLE']}"),
            const SizedBox(height: 8),
            Text("Prix HT: €${article['GA_PVHT']}"),
            Text("Prix TTC: €${article['GA_PVTTC']}"),
            const SizedBox(height: 8),
            if (article['REMISE'] != null)
              Text("Remise: ${article['REMISE']['MLR_REMISE']}%"),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(article['description'] ?? 'Aucune description.'),
          ],
        ),
      ),
    );
  }
}
