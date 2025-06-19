import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/services/home_service.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<Map<String, dynamic>> allArticles = [];
  List<Map<String, dynamic>> promotions = [];
  List<Map<String, dynamic>> nonPromotions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPromos();
  }

  Future<void> fetchPromos() async {
    setState(() => isLoading = true);
    try {
      allArticles = await ArticleService().getPromotedArticles();
      promotions = allArticles
          .where(
              (a) => a['remise'] != null && a['remise']['pourcentage'] != null)
          .toList();
      nonPromotions = allArticles
          .where(
              (a) => a['remise'] == null || a['remise']['pourcentage'] == null)
          .toList();
    } catch (e) {
      print("Erreur chargement promos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showRemiseDialog(BuildContext context, Map<String, dynamic> article) {
    final TextEditingController pourcentageCtrl = TextEditingController();
    final TextEditingController libelleCtrl = TextEditingController();
    final TextEditingController typeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter une promotion"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(article['libelle'] ?? ''),
            const SizedBox(height: 10),
            TextField(
              controller: pourcentageCtrl,
              decoration: const InputDecoration(labelText: "Pourcentage"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: libelleCtrl,
              decoration: const InputDecoration(labelText: "Libellé promo"),
            ),
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(labelText: "Type de remise"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final remiseData = {
                  "GA_ARTICLE": article["code"] ?? article["GA_CODEARTICLE"],
                  "MLR_TYPEREMISE": typeCtrl.text,
                  "GTR_LIBELLE": libelleCtrl.text,
                  "MLR_REMISE": double.tryParse(pourcentageCtrl.text) ?? 0,
                  "MLR_VALEURREMDEV": 0,
                  "MLR_MONTANTHTDEV": 0,
                  "MLR_MONTANTTTCDEV": 0,
                  "MLR_CODECOND": null,
                  "MLR_totalbase":
                      article["prix_base"] ?? article["GA_PVTTC"] ?? 0,
                  "MLR_DATEPIECE": DateTime.now().toIso8601String(),
                };

                await ArticleService().createRemise(remiseData);

                // ✅ Envoi de la notification à tous les clients
                await http.post(
                  Uri.parse("http://localhost:3000/notifications"),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "codeTiers": "C001", // ou null si notification broadcast
                    "title": "📢 Nouvelle promo sur ${article["libelle"]}",
                    "message":
                        "Profitez de ${pourcentageCtrl.text}% de réduction !"
                  }),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  fetchPromos();
                }
              } catch (e) {
                print("Erreur ajout promo: $e");
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> article, bool hasRemise) {
    final remise = article['remise'];
    final prixAvant = remise?['prix_avant'] ?? article['prix_base'] ?? 0;
    final prixApres = remise?['prix_apres'] ?? article['prix_remise'] ?? 0;
    final pourcentage = remise?['pourcentage']?.toStringAsFixed(0) ?? "0";

    return ListTile(
      tileColor: hasRemise ? Colors.white : Colors.grey.shade100,
      leading: const Icon(Icons.local_offer_outlined, color: Colors.red),
      title: Text(article['libelle'] ?? 'Sans libellé'),
      subtitle: hasRemise
          ? Text("Avant: €$prixAvant → Après: €$prixApres",
              style: const TextStyle(color: Colors.green))
          : const Text("Pas de remise", style: TextStyle(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRemise)
            Text("-$pourcentage%", style: const TextStyle(color: Colors.red)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
            tooltip: "Ajouter / Modifier promotion",
            onPressed: () => _showRemiseDialog(context, article),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Articles en promotion")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text("Articles en promotion",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...promotions.map((a) => _buildTile(a, true)),
                const SizedBox(height: 20),
                const Text("Autres articles",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...nonPromotions.map((a) => _buildTile(a, false)),
              ],
            ),
    );
  }
}
