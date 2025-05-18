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
  void initState() {
    super.initState();
    if (!hasFetched) {
      hasFetched = true;
      _fetchPanier();
    }
  }

  Future<void> _fetchPanier() async {
    print("📦 [_fetchPanier] called");
    setState(() => isLoading = true);
    try {
      final panierData = await PanierService().getPanier();
      print("📥 [_fetchPanier] panier reçu : $panierData");

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

  double get total => lignes.fold(0, (sum, l) => sum + (l['TotalLigne'] ?? 0));

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
                            trailing: Text("Total: €${ligne['TotalLigne']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
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
