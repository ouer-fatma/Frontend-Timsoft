import 'package:flutter/material.dart';

class SuiviCommandeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> articles;
  final double total;
  final String livraison;
  final String numeroCommande;

  const SuiviCommandeScreen({
    super.key,
    required this.articles,
    required this.total,
    required this.livraison,
    required this.numeroCommande,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suivi de commande")),
      backgroundColor: const Color(0xFFF7F5F2),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Commande n° $numeroCommande",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Livraison : $livraison"),
            const Divider(height: 32),
            const Text("Articles :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: articles.isEmpty
                  ? const Text("Aucun article.")
                  : ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (_, index) {
                        final item = articles[index];
                        final libelle = item['GA_LIBELLE'] ?? 'Article';
                        final quantite = item['GL_QTEFACT'] ?? '-';
                        final taille = item['dim1Libelle'] ?? '-';
                        final couleur = item['dim2Libelle'] ?? '-';
                        final totalLigne = item['TotalLigne'] ?? 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(libelle),
                              subtitle: Text(
                                  "Qté: $quantite • Taille: $taille • Couleur: $couleur"),
                              trailing: Text(
                                "${totalLigne.toStringAsFixed(2)} DT",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total TTC :",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("${total.toStringAsFixed(2)} DT",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Retour à l'accueil"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Fonction à venir : Génération de la facture PDF"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Télécharger la facture"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
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
