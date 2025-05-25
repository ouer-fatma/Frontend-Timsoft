import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null; // ✅ Réinitialise l'erreur à chaque appel
    });

    try {
      orders = await _orderService.fetchAllOrders();
    } catch (e) {
      print("Erreur récupération commandes: $e");
      errorMessage = e.toString(); // ✅ Stocke l'erreur
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) async {
    try {
      final details = await _orderService.getOrderDetails(
        nature: order['GP_NATUREPIECEG'].toString(),
        souche: order['GP_SOUCHE'].toString(),
        numero: int.parse(order['GP_NUMERO'].toString()), // 💡 explicitly int
        indice: order['GP_INDICEG'].toString(),
      );

      final commande = details['commande'];
      final lignes = List<Map<String, dynamic>>.from(details['lignes']);
      final total = details['TOTAL_APRES_REMISE'] ?? commande['GP_TOTALTTC'];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Détails de la commande"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Client: ${commande['GP_TIERS']}"),
                Text("Date: ${commande['GP_DATECREATION']}"),
                Text("Total TTC: $total €"),
                const SizedBox(height: 10),
                const Divider(),
                const Text("Lignes:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...lignes.map((l) => ListTile(
                      title: Text(l['GA_LIBELLE'] ?? 'Sans libellé'),
                      subtitle: Text(
                          "Article: ${l['GL_ARTICLE']}  x ${l['GL_QTEFACT']}"),
                      trailing: Text("${l['GL_TOTALLIGNE']} €"),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Fermer"),
            ),
          ],
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Erreur: $errorMessage",
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                            "Commande: ${order['GP_NATUREPIECEG']}/${order['GP_SOUCHE']}/${order['GP_NUMERO']}/${order['GP_INDICEG']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client: ${order['GP_TIERS']}"),
                            Text("Date: ${order['GP_DATECREATION']}"),
                            Text("Total TTC: ${order['GP_TOTALTTC']} €"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf,
                                  color: Colors.deepPurple),
                              onPressed: () async {
                                final String nature =
                                    order['GP_NATUREPIECEG'].toString();
                                final String souche =
                                    order['GP_SOUCHE'].toString();
                                final int numero =
                                    int.parse(order['GP_NUMERO'].toString());
                                final String indice =
                                    order['GP_INDICEG'].toString();

                                final String url =
                                    'http://127.0.0.1:3000/api/invoice/download/$nature/$souche/$numero/$indice';

                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Impossible d'ouvrir le PDF.")),
                                  );
                                }
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
