import 'package:flutter/material.dart';
import 'package:project/screens/User/order_detail_screen.dart';
import 'package:project/services/order_service.dart';
import 'package:project/services/storage_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key, required String codeTiers});

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
      final orders = await OrderService().fetchClientOrders();
      setState(() {
        this.orders = orders;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
      setState(() {
        isLoading = false;
      });
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
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        title: Text("Commande N°: ${order['GP_NUMERO']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${order['GP_DATECREATION']}"),
                            Text(
                              "Statut: ${order['GP_STATUTPIECE'] == 'ENR' ? '✅ Enregistrée' : '⏳ En attente'}",
                              style: TextStyle(
                                color: order['GP_STATUTPIECE'] == 'ENR'
                                    ? Colors.green
                                    : Colors.orange,
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailScreen(order: order),
                                  ),
                                );
                              },
                            ),
                            if (order['GP_STATUTPIECE'] ==
                                'ATT') // 👈 Seulement les commandes en attente
                              IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Annuler',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Confirmation"),
                                      content: const Text(
                                          "Voulez-vous annuler cette commande ?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Non"),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text("Oui"),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await OrderService().deleteOrder(
                                        nature: order['GP_NATUREPIECEG'],
                                        souche: order['GP_SOUCHE'],
                                        numero: order['GP_NUMERO'],
                                        indice: order['GP_INDICEG'],
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("Commande annulée.")),
                                      );
                                      _fetchClientOrders() ;
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
