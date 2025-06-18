import 'package:flutter/material.dart';
import 'package:project/screens/User/order_detail_screen.dart';
import 'package:project/services/order_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key,required String codeTiers
  });

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClientOrders();
  }

  Future<void> _fetchClientOrders() async {
    try {
      final fetchedOrders = await _orderService.fetchClientOrders();
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getStatutLabel(String code) {
    switch (code) {
      case 'ENR':
        return '✅ Enregistrée';
      case 'ATT':
        return '⏳ En attente';
      case 'EXP':
        return '📦 Expédiée';
      default:
        return '❓ Inconnu';
    }
  }

  Color getStatutColor(String code) {
    switch (code) {
      case 'ENR':
        return Colors.green;
      case 'ATT':
        return Colors.orange;
      case 'EXP':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Commandes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text("Aucune commande trouvée."))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final statut = order['GP_STATUTPIECE'] ?? 'ATT';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        title: Text("Commande N°: ${order['GP_NUMERO']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${order['GP_DATECREATION'] ?? ''}"),
                            const SizedBox(height: 4),
                            Text(
                              "Statut: ${getStatutLabel(statut)}",
                              style: TextStyle(
                                color: getStatutColor(statut),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                final nature = order['GP_NATUREPIECEG'];
                                final souche = order['GP_SOUCHE'];
                                final indice = order['GP_INDICEG'];
                                final numero = order['GP_NUMERO'];

                                if (nature == null || souche == null || indice == null || numero == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Détails indisponibles pour cette commande.")),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                            ),
                            if (statut == 'ATT')
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Annuler',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Confirmation"),
                                      content: const Text("Voulez-vous annuler cette commande ?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Non"),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text("Oui"),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await _orderService.deleteOrder(
                                        nature: order['GP_NATUREPIECEG'],
                                        souche: order['GP_SOUCHE'],
                                        numero: order['GP_NUMERO'],
                                        indice: order['GP_INDICEG'],
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Commande annulée.")),
                                      );
                                      _fetchClientOrders();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Erreur : $e")),
                                      );
                                    }
                                  }
                                },
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
