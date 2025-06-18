import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/services/order_service.dart';
import 'package:project/services/retour_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;
  final RetourService _retourService = RetourService();

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    try {
      final res = await OrderService().getOrderDetails(
        nature: widget.order['GP_NATUREPIECEG'].toString(),
        souche: widget.order['GP_SOUCHE'].toString(),
        numero: int.parse(widget.order['GP_NUMERO'].toString()),
        indice: widget.order['GP_INDICEG'].toString(),
      );
      setState(() {
        details = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  void showRetourDialog(
    String articleCode,
    int maxQty,
    String depot,
    String clientCode,
  ) {
    final _qtyController = TextEditingController();
    String selectedMode = 'remboursement';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text("Retourner l’article"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Quantité à retourner (max $maxQty)"),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "1"),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedMode,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() => selectedMode = value);
                    }
                  },
                  items: ['remboursement', 'échange'].map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode),
                    );
                  }).toList(),
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
                  final qty = int.tryParse(_qtyController.text.trim());
                  if (qty == null || qty <= 0 || qty > maxQty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Quantité invalide")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    await _retourService.createRetour(
                      article: articleCode,
                      quantite: qty,
                      depot: depot,
                      utilisateur: clientCode,
                      modeRetour: selectedMode,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Retour enregistré.")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Erreur : $e")),
                    );
                  }
                },
                child: const Text("Confirmer"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commande = details?['commande'];
    final lignes = List<Map<String, dynamic>>.from(details?['lignes'] ?? []);
    final total = details?['TOTAL_APRES_REMISE'];
    final nomClient = commande?['GP_NOMTIERS'] ?? 'Client';
    final statut = commande?['GP_STATUTPIECE'] ?? 'N/A';
    final dateStr = commande?['GP_DATECREATION'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final isRetrait = commande?['GP_LIBRETIERS1'] == 'S01';
    final depotCode = commande?['GP_DEPOT'] ?? '';
    final clientCode = commande?['GP_TIERS'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Détails Commande")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text("🧑 Client: $nomClient",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  if (date != null)
                    Text("📅 Date: ${DateFormat.yMMMMd().add_Hm().format(date)}"),
                  Text("📦 Statut: $statut",
                      style: const TextStyle(color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  Text(
                    "Mode : ${isRetrait ? '🛍 Retrait en dépôt' : '🚚 Livraison'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (isRetrait && depotCode.isNotEmpty)
                    Text("Dépôt : $depotCode"),
                  const Divider(height: 30),
                  const Text("🧾 Lignes de commande:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...lignes.map((ligne) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(ligne['GA_LIBELLE'] ?? 'Article'),
                          subtitle: Text(
                            "x ${ligne['GL_QTEFACT']} | ${ligne['GL_ARTICLE']} | ${ligne['GL_CODESDIM'] ?? ''}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "€${ligne['GL_TOTALLIGNE']?.toStringAsFixed(2) ?? '0.00'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () {
                                  showRetourDialog(
                                    ligne['GL_ARTICLE'],
                                    ligne['GL_QTEFACT'].toInt(),
                                    depotCode,
                                    clientCode,
                                  );
                                },
                                child: const Text("Retourner"),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const Divider(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Total TTC: €${(total ?? 0).toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
