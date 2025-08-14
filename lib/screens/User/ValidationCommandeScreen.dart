import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/screens/User/suivi_commande_screen.dart';
import 'package:project/services/panier_service.dart';
import 'package:project/services/storage_service.dart';

class ValidationCommandeScreen extends StatefulWidget {
  const ValidationCommandeScreen({super.key});

  @override
  State<ValidationCommandeScreen> createState() =>
      _ValidationCommandeScreenState();
}

class _ValidationCommandeScreenState extends State<ValidationCommandeScreen> {
  List<Map<String, dynamic>> panier = [];
  List<Map<String, dynamic>> depots = [];
  String? selectedDepot;
  bool retraitMagasin = false;
  bool isLoading = true;

  double get sousTotal =>
      panier.fold(0.0, (sum, item) => sum + (item['TotalLigne'] ?? 0.0));
  double get fraisLivraison =>
      retraitMagasin ? 0.0 : (sousTotal < 100 ? 7.0 : 0.0);
  double get totalTTCaPayer => sousTotal + fraisLivraison;

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

  Future<void> _fetchDepots() async {
    try {
      final res = await http
          .get(Uri.parse("http://localhost:3000/click-collect/depots"));
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

  Future<void> _confirmerCommande() async {
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

    if (retraitMagasin && selectedDepot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un dépôt.")),
      );
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
        "GP_LIBRETIERS1": retraitMagasin ? "S01" : "LOC",
        "GP_DEPOT": retraitMagasin ? selectedDepot : null,
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
        final data = jsonDecode(postRes.body);

        final nature = data['GP_NATUREPIECEG'];
        final souche = data['GP_SOUCHE'];
        final numero = data['GP_NUMERO'];
        final indice = data['GP_INDICEG'];

        final livraison =
            retraitMagasin ? "Retrait en magasin" : "Livraison à domicile";
        final numeroCommande = numero.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Commande enregistrée avec succès.")),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SuiviCommandeScreen(
              articles: panier,
              total: totalTTCaPayer,
              livraison: livraison,
              numeroCommande: numeroCommande,
              nature: nature,
              souche: souche,
              numero: numero,
              indice: indice,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${postRes.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
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
                      const Text("Sous-total (TTC) :",
                          style: TextStyle(fontSize: 16)),
                      Text("${sousTotal.toStringAsFixed(2)} DT"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Livraison :", style: TextStyle(fontSize: 16)),
                      Text(
                        retraitMagasin
                            ? "Gratuit"
                            : fraisLivraison == 0
                                ? "Gratuit"
                                : "${fraisLivraison.toStringAsFixed(2)} DT",
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total TTC à payer :",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${totalTTCaPayer.toStringAsFixed(2)} DT",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Méthode de livraison :",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioListTile(
                    title: const Text("Retrait en magasin"),
                    value: true,
                    groupValue: retraitMagasin,
                    onChanged: (val) {
                      setState(() {
                        retraitMagasin = val as bool;
                        selectedDepot = null;
                        depots.clear();
                        _fetchDepots();
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text("Livraison à domicile"),
                    value: false,
                    groupValue: retraitMagasin,
                    onChanged: (val) {
                      setState(() {
                        retraitMagasin = val as bool;
                        selectedDepot = null;
                      });
                    },
                  ),
                  if (retraitMagasin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: depots.isEmpty
                          ? const Text("Chargement des dépôts...")
                          : DropdownButtonFormField<String>(
                              value: selectedDepot,
                              decoration: const InputDecoration(
                                  labelText: "Choisissez un dépôt"),
                              items: depots.map((depot) {
                                final code = depot['code']
                                    .toString(); // ✅ Correction ici
                                final label =
                                    depot['libelle'] ?? 'Dépôt inconnu';
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (val) => setState(
                                  () => selectedDepot = val?.toString()),
                            ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: panier.isEmpty ? null : _confirmerCommande,
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
