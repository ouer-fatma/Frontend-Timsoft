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

  List<Map<String, dynamic>> depots = [];
  String? selectedDepot;

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
    try {
      final panierData = await _panierService.getPanier(codeTiers: widget.codeTiers);
      setState(() {
        lignes = panierData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _fetchDepots() async {
    try {
      final res = await http.get(Uri.parse("http://localhost:3000/click-collect/depots"));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() => depots = data.cast<Map<String, dynamic>>());
      } else {
        print("Erreur code ${res.statusCode} : ${res.body}");
      }
    } catch (e) {
      print("Erreur chargement dépôts: $e");
    }
  }

  Future<void> _supprimerArticle(String codeArticle, String codeSDIM) async {
    try {
      await _panierService.supprimerDuPanier(widget.codeTiers, codeArticle, codesdim: codeSDIM);
      setState(() => lignes.removeWhere((l) =>
          l['GL_ARTICLE'] == codeArticle && l['GL_CODESDIM'] == codeSDIM));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Article supprimé.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur suppression : $e")));
    }
  }

  Future<void> _validerCommande() async {
    final token = await StorageService.getToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Authentification invalide.")));
      return;
    }

    final decoded = JwtDecoder.decode(token);
    final codeTiers = decoded['codeTiers'];
    if (codeTiers == null) return;

    if (isRetrait && selectedDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir un dépôt.")));
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("http://localhost:3000/orders/next-numero"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode != 200) throw Exception("Erreur numéro");

      final numero = jsonDecode(res.body)['nextNumero'];
      final now = DateTime.now().toUtc().toIso8601String();

      final body = {
        "GP_NATUREPIECEG": "CC",
        "GP_SOUCHE": "04",
        "GP_NUMERO": numero,
        "GP_INDICEG": 1,
        "GP_DATECREATION": now,
        "GP_LIBRETIERS1": isRetrait ? "S01" : "LOC",
        "GP_DEPOT": isRetrait ? selectedDepot : null
      };

      final postRes = await http.post(
        Uri.parse("http://localhost:3000/orders"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );

      if (postRes.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Commande enregistrée avec succès.")),
        );
        setState(() => lignes.clear());
        _fetchPanier();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${postRes.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  double get total => lignes.fold(0.0, (sum, l) => sum + (l['TotalLigne'] ?? 0));

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
                          final l = lignes[index];
                          return ListTile(
                            title: Text(l['GA_LIBELLE'] ?? ''),
                            subtitle: Text("Quantité: ${l['GL_QTEFACT']} | Prix: €${l['GA_PVTTC']}\n"
                                "Taille: ${l['dim1Libelle'] ?? '-'} | Couleur: ${l['dim2Libelle'] ?? '-'}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("€${(l['TotalLigne'] ?? 0).toStringAsFixed(2)}"),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerArticle(l['GL_ARTICLE'], l['GL_CODESDIM']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            title: const Text("Retrait en dépôt"),
                            value: isRetrait,
                            onChanged: (val) {
                              setState(() {
                                isRetrait = val;
                                if (val) {
                                  _fetchDepots();
                                  selectedDepot = null;
                                }
                              });
                            },
                          ),
                          if (isRetrait)
                            depots.isNotEmpty
                                ? DropdownButtonFormField<String>(
                                    value: depots.any((d) => d['code'] == selectedDepot) ? selectedDepot : null,
                                    decoration: const InputDecoration(labelText: "Choisissez un dépôt"),
                                    items: depots.map((depot) {
                                      final code = depot['code'];
                                      final label = depot['libelle'] ?? 'Dépôt inconnu';
                                      return DropdownMenuItem<String>(
                                        value: code,
                                        child: Text(label),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => selectedDepot = val),
                                  )
                                : const Text("Aucun dépôt disponible."),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total panier:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("€${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: lignes.isEmpty || (isRetrait && selectedDepot == null)
                                ? null
                                : _validerCommande,
                            child: const Text("Valider la commande"),
                          )
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
