import 'package:flutter/material.dart';
import 'package:project/services/panier_service.dart';

class PanierScreen extends StatefulWidget {
  final String codeTiers;
  const PanierScreen({super.key, required this.codeTiers});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final PanierService _panierService = PanierService();
  List<dynamic> lignes = [];
  bool isLoading = true;
  bool hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!hasFetched) {
      hasFetched = true;
      _fetchPanier(); // 👈 on déplace ici
    }
  }

 Future<void> _fetchPanier() async {
  print("📦 [_fetchPanier] called");
  setState(() => isLoading = true);

  final stopwatch = Stopwatch()..start(); // mesurer le temps

  try {
    final panierData = await _panierService.getPanier();
    final elapsed = stopwatch.elapsedMilliseconds;

    // ✅ petit délai si c’est trop rapide pour donner un effet "chargement"
    if (elapsed < 300) {
      await Future.delayed(Duration(milliseconds: 300 - elapsed));
    }

    setState(() {
      lignes = panierData;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur: $e")),
    );
  }
}

  Future<void> _supprimerArticle(String codeArticle) async {
    try {
      await _panierService.supprimerDuPanier(widget.codeTiers, codeArticle);
      setState(() {
        lignes.removeWhere((ligne) => ligne['GL_ARTICLE'] == codeArticle);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Article supprimé du panier.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur suppression : $e")),
      );
    }
  }

  double get total =>
      lignes.fold(0.0, (sum, l) => sum + (l['TotalLigne'] ?? 0));

  @override
  Widget build(BuildContext context) {
    print("🔁 [build] PanierScreen reconstruit");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Panier"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lignes.isEmpty
              ? const Center(child: Text("Votre panier est vide."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: lignes.length,
                        itemBuilder: (context, index) {
                          final ligne = lignes[index];
                          return ListTile(
                            title: Text(ligne['GA_LIBELLE'] ?? 'Sans libellé'),
                            subtitle: Text(
                              "Quantité: ${ligne['GL_QTEFACT']} | Prix: €${ligne['GA_PVTTC']}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "€${ligne['TotalLigne']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _supprimerArticle(ligne['GL_ARTICLE']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total panier:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "€${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
