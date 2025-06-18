// Imports
import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      orders = await _orderService.fetchAllOrders();
      orders.sort((a, b) {
        final da = DateTime.tryParse(a['GP_DATECREATION'] ?? '') ?? DateTime(1900);
        final db = DateTime.tryParse(b['GP_DATECREATION'] ?? '') ?? DateTime(1900);
        return db.compareTo(da);
      });
    } catch (e) {
      errorMessage = e.toString();
    }

    setState(() => isLoading = false);
  }

  Future<void> _launchPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le PDF.")),
      );
    }
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) async {
    try {
      final details = await _orderService.getOrderDetails(
        nature: order['GP_NATUREPIECEG'].toString(),
        souche: order['GP_SOUCHE'].toString(),
        numero: int.tryParse(order['GP_NUMERO']?.toString() ?? '') ?? 0,
        indice: order['GP_INDICEG'].toString(),
      );

      final commande = details['commande'];
      final lignes = List<Map<String, dynamic>>.from(details['lignes']);
      final total = details['TOTAL_APRES_REMISE'] ?? commande['GP_TOTALTTC'];

      final depots = await _orderService.getDepotsDisponibles(
        nature: order['GP_NATUREPIECEG'].toString(),
        souche: order['GP_SOUCHE'].toString(),
        numero: int.tryParse(order['GP_NUMERO']?.toString() ?? '') ?? 0,
        indice: order['GP_INDICEG'].toString(),
      );

      final Map<String, String?> depotsSelectionnes = {};

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text("Détails de la commande"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Client: ${commande['GP_TIERS']}"),
                  Text("Date: ${commande['GP_DATECREATION'] ?? '—'}"),
                  Text("Total TTC: ${total ?? '—'} €"),
                  const Divider(),
                  const Text("Lignes:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...lignes.map((l) {
                    final articleCode = l['GL_ARTICLE'].toString();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['GA_LIBELLE'] ?? 'Sans libellé', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Article: $articleCode x ${l['GL_QTEFACT']}", style: const TextStyle(fontSize: 12)),
                        Text("Prix: ${l['GL_TOTALLIGNE']} €"),
                        DropdownButton<String>(
                          hint: const Text("Choisir un dépôt"),
                          value: depotsSelectionnes[articleCode],
                          isExpanded: true,
                          onChanged: (val) => setState(() => depotsSelectionnes[articleCode] = val),
                          items: depots.map<DropdownMenuItem<String>>((depot) {
                            return DropdownMenuItem<String>(
                              value: depot['depot'].toString(),
                              child: Text("Dépôt ${depot['depot']} (Stock: ${depot['quantite']})"),
                            );
                          }).toList(),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);

                  final cleaned = depotsSelectionnes.map((key, value) => MapEntry(key, value ?? ''))
                    ..removeWhere((key, value) => value.isEmpty);

                 await _orderService.generateAndDownloadBLWithMultipleDepots(
  nature: order['GP_NATUREPIECEG'].toString(),
  souche: order['GP_SOUCHE'].toString(),
  numero: int.tryParse(order['GP_NUMERO']?.toString() ?? '') ?? 0,
  indice: order['GP_INDICEG'].toString(),
  depotsParArticle: Map<String, String>.from(cleaned),
);

                },
                child: const Text("Générer BL"),
              )
            ],
          ),
        ),
      );
    } catch (e) {
      print("Erreur détails commande: $e");
    }
  }

  void _confirmDelete(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la commande"),
        content: const Text("Voulez-vous vraiment supprimer cette commande ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _orderService.deleteOrder(
                  nature: order['GP_NATUREPIECEG'],
                  souche: order['GP_SOUCHE'],
                  numero: order['GP_NUMERO'],
                  indice: order['GP_INDICEG'],
                );
                fetchOrders();
              } catch (e) {
                print("Erreur suppression: $e");
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Commandes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text("Erreur: $errorMessage", style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final String nature = order['GP_NATUREPIECEG'].toString();
                    final String souche = order['GP_SOUCHE'].toString();
                    final int? numero = int.tryParse(order['GP_NUMERO']?.toString() ?? '');
                    final String indice = order['GP_INDICEG'].toString();

                    if (numero == null) return const SizedBox();

                    final String dateStr = order['GP_DATECREATION'] != null
                        ? DateTime.tryParse(order['GP_DATECREATION'])?.toLocal().toString().split('.').first ?? '—'
                        : '—';

                    final String totalTTC = order['GP_TOTALTTC'] != null
                        ? '${order['GP_TOTALTTC']} €'
                        : '—';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        title: Text("Commande: $nature/$souche/$numero/$indice"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client: ${order['GP_TIERS']}"),
                            Text("Date: $dateStr"),
                            Text("Total TTC: $totalTTC"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.blue),
                              tooltip: 'Détails',
                              onPressed: () => _showOrderDetailsDialog(order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                              tooltip: 'Télécharger Facture',
                              onPressed: () {
                                final url = 'http://127.0.0.1:3000/api/invoice/download/$nature/$souche/$numero/$indice';
                                _launchPdf(url);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(order),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
