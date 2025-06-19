import 'package:flutter/material.dart';
import 'package:project/screens/User/suivi_commande_screen.dart';
import 'package:project/services/panier_service.dart';

class ValidationCommandeScreen extends StatefulWidget {
  const ValidationCommandeScreen({super.key});

  @override
  State<ValidationCommandeScreen> createState() =>
      _ValidationCommandeScreenState();
}

class _ValidationCommandeScreenState extends State<ValidationCommandeScreen> {
  List<Map<String, dynamic>> panier = [];
  bool retraitMagasin = false;
  bool isLoading = true;

  double get sousTotal =>
      panier.fold(0.0, (sum, item) => sum + (item['TotalLigne'] ?? 0.0));

  double get tva => sousTotal * 0.19;
  double get total => sousTotal + tva;

  @override
  void initState() {
    super.initState();
    _loadPanier();
  }

  Future<void> _loadPanier() async {
    try {
      final data = await PanierService().getPanier();
      setState(() {
        panier = data;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement panier: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validation de la commande")),
      backgroundColor: const Color(0xFFF7F5F2),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Vos articles :",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: panier.isEmpty
                        ? const Center(child: Text("Votre panier est vide."))
                        : ListView.builder(
                            itemCount: panier.length,
                            itemBuilder: (_, index) {
                              final item = panier[index];
                              return ListTile(
                                title: Text(item['GA_LIBELLE'] ?? 'Article'),
                                subtitle: Text(
                                  "Qté: ${item['GL_QTEFACT']} • Taille: ${item['dim1Libelle']} • Couleur: ${item['dim2Libelle']}",
                                ),
                                trailing: Text(
                                  "${(item['TotalLigne'] ?? 0.0).toStringAsFixed(2)} DT",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sous-total :",
                          style: TextStyle(fontSize: 16)),
                      Text("${sousTotal.toStringAsFixed(2)} DT"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TVA (19%) :", style: TextStyle(fontSize: 16)),
                      Text("${tva.toStringAsFixed(2)} DT"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total TTC :",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${total.toStringAsFixed(2)} DT",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Méthode de livraison :",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioListTile(
                    title: const Text("Retrait en magasin"),
                    value: true,
                    groupValue: retraitMagasin,
                    onChanged: (val) =>
                        setState(() => retraitMagasin = val as bool),
                  ),
                  RadioListTile(
                    title: const Text("Livraison à domicile"),
                    value: false,
                    groupValue: retraitMagasin,
                    onChanged: (val) =>
                        setState(() => retraitMagasin = val as bool),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: panier.isEmpty
                        ? null
                        : () {
                            final articlesCopy =
                                List<Map<String, dynamic>>.from(panier);
                            final livraison = retraitMagasin
                                ? "Retrait en magasin"
                                : "Livraison à domicile";
                            final numeroCommande =
                                "CMD${DateTime.now().millisecondsSinceEpoch}";

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => SuiviCommandeScreen(
                                  articles: articlesCopy,
                                  total: total,
                                  livraison: livraison,
                                  numeroCommande: numeroCommande,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text("Confirmer la commande",
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
