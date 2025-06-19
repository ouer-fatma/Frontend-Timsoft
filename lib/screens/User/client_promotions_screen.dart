import 'package:flutter/material.dart';
import 'package:project/services/home_service.dart';

class ClientPromotionsScreen extends StatefulWidget {
  const ClientPromotionsScreen({super.key});

  @override
  State<ClientPromotionsScreen> createState() => _ClientPromotionsScreenState();
}

class _ClientPromotionsScreenState extends State<ClientPromotionsScreen> {
  List<Map<String, dynamic>> promotions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPromotions();
  }

  Future<void> fetchPromotions() async {
    setState(() => isLoading = true);
    try {
      final fetched = await ArticleService().getPromotedArticles();
      promotions = fetched.where((a) {
        final remise = a['remise'];
        final prixAvant =
            remise?['prix_avant'] ?? a['prix_base'] ?? a['GA_PVTTC'];
        final prixApres = remise?['prix_apres'] ?? a['prix_remise'];

        return remise != null &&
            remise['pourcentage'] != null &&
            prixAvant != null &&
            prixApres != null &&
            prixAvant > prixApres;
      }).toList();
    } catch (e) {
      print("Erreur chargement promotions: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("Promotions")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: promotions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth < 600 ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) {
                final article = promotions[index];
                final remise = article['remise'];
                final prixAvant = remise?['prix_avant'] ??
                    article['prix_base'] ??
                    article['GA_PVTTC'] ??
                    0.0;

                final prixApres =
                    remise?['prix_apres'] ?? article['prix_remise'] ?? 0.0;
                final pourcentage = remise['pourcentage'] ?? 0;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Image produit
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              article['GA_IMAGE_URL'] ?? '',
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported,
                                    size: 40),
                              ),
                            ),
                          ),
                          // Badge réduction
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${pourcentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article['libelle'] ?? 'Sans nom',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '€${prixApres.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '€${prixAvant.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
