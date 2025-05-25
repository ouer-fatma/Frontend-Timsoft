import 'package:flutter/material.dart';
import 'package:project/services/panier_service.dart';
import 'package:project/services/storage_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final PanierService _panierService = PanierService();
  String? codeTiers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userData = await StorageService.getUserData();
    setState(() {
      codeTiers = userData['codeTiers'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article['GA_LIBELLE'] ?? 'Détail Article'),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Partie image à gauche
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.article['GA_IMAGE_URL'] != null
                    ? Image.network(
                        widget.article['GA_IMAGE_URL'],
                        fit: BoxFit.cover,
                        height: 400,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 100),
                      )
                    : const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            const SizedBox(width: 24),

            // 📋 Partie texte à droite
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article['GA_LIBELLE'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Code: ${widget.article['GA_CODEARTICLE']}"),
                  const SizedBox(height: 8),
                  Text(
                    "Prix TTC: €${widget.article['GA_PVTTC']}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  codeTiers != null
                      ? ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);

                                  try {
                                    await _panierService.ajouterAuPanier(
                                      codeTiers: codeTiers!,
                                      codeArticle:
                                          widget.article['GA_CODEARTICLE'],
                                      quantite: 1,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Ajouté au panier !")),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Erreur: $e")),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Ajouter au panier"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5BDB),
                            foregroundColor: Colors.white,
                          ),
                        )
                      : const Text(
                          "Connectez-vous pour ajouter au panier",
                          style: TextStyle(color: Colors.grey),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
