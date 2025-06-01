import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/services/panier_service.dart';
import 'package:project/services/storage_service.dart';

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
  bool isRetrait = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!hasFetched) {
      hasFetched = true;
      _fetchPanier();
    }
  }

  Future<void> _fetchPanier() async {
    setState(() => isLoading = true);
    final stopwatch = Stopwatch()..start();

    try {
      final panierData = await _panierService.getPanier(codeTiers: widget.codeTiers);
      final elapsed = stopwatch.elapsedMilliseconds;
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

  Future<void> _supprimerArticle(String codeArticle, String codeSDIM) async {
    try {
      await _panierService.supprimerDuPanier(
        widget.codeTiers,
        codeArticle,
        codesdim: codeSDIM,
      );

      setState(() {
        lignes.removeWhere((ligne) =>
            ligne['GL_ARTICLE'] == codeArticle &&
            ligne['GL_CODESDIM'] == codeSDIM);
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

  Future<void> _validerCommande() async {
  final token = await StorageService.getToken();
  if (token == null || JwtDecoder.isExpired(token)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Authentification invalide.")),
    );
    return;
  }

  final decoded = JwtDecoder.decode(token);
  final codeTiers = decoded['codeTiers'];
  if (codeTiers == null) return;

  try {
    final numeroRes = await http.get(
      Uri.parse("http://localhost:3000/orders/next-numero"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (numeroRes.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur génération numéro de commande.")),
      );
      return;
    }

    final bodyDecoded = jsonDecode(numeroRes.body);
    final numero = bodyDecoded['nextNumero'];

    if (lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Panier vide ou invalide.")),
      );
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    final body = {
      "GP_NATUREPIECEG": "CC", // ✅ Correct nature pièce commande
      "GP_SOUCHE": "04",
      "GP_NUMERO": numero,
      "GP_INDICEG": 1,
      "GP_DATECREATION": now,
      "GP_LIBRETIERS1": isRetrait ? "S01" : "LOC",
      "GP_DEPOT": isRetrait ? "113" : null
    };

    final response = await http.post(
      Uri.parse("http://localhost:3000/orders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Commande créée avec succès.")),
      );
      setState(() {
        lignes.clear();
      });
      await _fetchPanier(); // 🆕 Optionnel : refresh l'écran panier
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec commande: ${response.body}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Erreur: $e")),
    );
  }
}


  double get total =>
      lignes.fold(0.0, (sum, l) => sum + (l['TotalLigne'] ?? 0));

  @override
  Widget build(BuildContext context) {
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
                          final dim1 = ligne['dim1Libelle'] ?? '-';
                          final dim2 = ligne['dim2Libelle'] ?? '-';

                          return ListTile(
                            title: Text(ligne['GA_LIBELLE'] ?? 'Sans libellé'),
                            subtitle: Text(
                              "Quantité: ${ligne['GL_QTEFACT']} | Prix: €${ligne['GA_PVTTC']}\n"
                              "Taille: $dim1 | Couleur: $dim2",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "€${ligne['TotalLigne'].toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerArticle(
                                    ligne['GL_ARTICLE'],
                                    ligne['GL_CODESDIM'],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            title: const Text("Retrait en dépôt"),
                            value: isRetrait,
                            onChanged: (val) => setState(() => isRetrait = val),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total panier:",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "€${total.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _validerCommande,
                            child: const Text("Valider la commande"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
