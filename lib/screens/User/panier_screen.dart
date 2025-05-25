import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/screens/User/create_order_screen.dart';
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
  bool isRetrait = false; // Par défaut livraison (LOC)
  List<dynamic> panier = [];

  @override
  void initState() {
    super.initState();
    if (!hasFetched) {
      hasFetched = true;
      _fetchPanier();
    }
  }

  Future<void> _validerCommande() async {
    final token = await StorageService.getToken();
    if (token == null) {
      print("❌ Token manquant !");
      return;
    }

    final decoded = JwtDecoder.decode(token);
    final codeTiers = decoded['codeTiers'];
    if (codeTiers == null) {
      print("❌ codeTiers manquant !");
      return;
    }

    try {
      // 🔄 Obtenir le nouveau numéro de commande depuis le backend
      final numeroRes = await http.get(
        Uri.parse("http://localhost:3000/orders/next-numero"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (numeroRes.statusCode != 200) {
        print("❌ Erreur obtention numéro: ${numeroRes.body}");
        return;
      }

      final bodyDecoded = jsonDecode(numeroRes.body);
      if (!bodyDecoded.containsKey('nextNumero')) {
        print("❌ Erreur: champ nextNumero manquant dans la réponse.");
        return;
      }

      final numero = bodyDecoded['nextNumero'];

      // ✅ Récupérer les lignes valides du panier (exclure les fakes comme "0000000")
      final lignesCommande = lignes
          .where((item) => item["GL_ARTICLE"] != "0000000")
          .map((item) => {
                "GL_ARTICLE": item["GL_ARTICLE"],
                "GL_QTEFACT": item["GL_QTEFACT"],
              })
          .toList();

      if (lignesCommande.isEmpty) {
        print("❌ Aucun article valide dans le panier.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Panier vide ou invalide.")),
        );
        return;
      }

      final now = DateTime.now().toUtc().toIso8601String();

      final body = {
        "GP_NATUREPIECEG": "SAM", // ou "CMD" selon logique
        "GP_SOUCHE": "04", // selon ta base
        "GP_NUMERO": numero,
        "GP_INDICEG": 1,
        "GP_DATECREATION": now,
        "GP_LIBRETIERS1": "LOC", // ou "S01" si tu ajoutes un switch
        "GP_DEPOT": null, // ou "113" si retrait
        "lignes": lignesCommande
      };

      print("🟡 Corps envoyé: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse("http://localhost:3000/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      print("Réponse création commande: ${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Commande créée avec succès.")),
        );
        setState(() {
          lignes.clear(); // vider le panier local
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Échec commande: ${response.body}")),
        );
      }
    } catch (e) {
      print("❌ Erreur validation commande: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur: $e")),
      );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            title: const Text("Retrait en dépôt"),
                            value: isRetrait,
                            onChanged: (val) {
                              setState(() {
                                isRetrait = val;
                              });
                            },
                          ),
                          Row(
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _validerCommande,
                            child: Text("Valider la commande"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
