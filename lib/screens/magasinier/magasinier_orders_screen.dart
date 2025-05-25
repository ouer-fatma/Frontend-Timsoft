import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';
import 'package:project/screens/magasinier/magasinier_order_detail_screen.dart';

class MagasinierOrdersScreen extends StatefulWidget {
  const MagasinierOrdersScreen({super.key});

  @override
  State<MagasinierOrdersScreen> createState() => _MagasinierOrdersScreenState();
}

class _MagasinierOrdersScreenState extends State<MagasinierOrdersScreen> {
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
      final allOrders = await _orderService.fetchAllOrders();
      // 🔍 Filtrer uniquement les commandes en attente
      orders = allOrders.where((o) => o['GP_STATUT'] == 'ATT').toList();
    } catch (e) {
      errorMessage = e.toString();
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes à traiter"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text("Erreur : $errorMessage"))
              : orders.isEmpty
                  ? const Center(child: Text("Aucune commande en attente."))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              "CMD ${order['GP_NUMERO']} • ${order['GP_TIERS']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Date: ${order['GP_DATECREATION']}"),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MagasinierOrderDetailScreen(order: order),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
