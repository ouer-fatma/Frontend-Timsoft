import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    final commande = details?['commande'];
    final lignes = List<Map<String, dynamic>>.from(details?['lignes'] ?? []);
    final total = details?['TOTAL_APRES_REMISE'];
    final nomClient = commande?['GP_NOMTIERS'] ?? 'Client';
    final statut = commande?['GP_STATUTPIECE'] ?? 'N/A';
    final dateStr = commande?['GP_DATECREATION'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

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
                    Text(
                        "📅 Date: ${DateFormat.yMMMMd().add_Hm().format(date)}"),
                  const SizedBox(height: 4),
                  Text("📦 Statut: $statut",
                      style: const TextStyle(color: Colors.blueAccent)),
                  const Divider(height: 32),
                  const Text("🧾 Lignes de commande:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...lignes.map((ligne) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(ligne['GA_LIBELLE'] ?? 'Article'),
                          subtitle: Text(
                              "x ${ligne['GL_QTEFACT']} | ${ligne['GL_ARTICLE']}"),
                          trailing: Text(
                            "€${ligne['GL_TOTALLIGNE']?.toStringAsFixed(2) ?? '0.00'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
