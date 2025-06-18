import 'package:flutter/material.dart';
import 'package:project/screens/magasinier/magasinier_order_detail_screen.dart';
import 'package:project/services/order_service.dart';

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
      final blOrders = await _orderService.fetchOrdersForMagasinier();
      final reservations = await _orderService.fetchReservationsPourMagasinier();

      final List<Map<String, dynamic>> allOrders = [...blOrders, ...reservations];

      allOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a['GP_DATEPIECE'] ?? a['GP_DATECREATION'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['GP_DATEPIECE'] ?? b['GP_DATECREATION'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      setState(() {
        orders = allOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Exception: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  String getStatutLabel(String code) {
    switch (code) {
      case 'EXP':
        return 'Expédiée';
      case 'ATT':
        return 'En attente';
      case 'PRE':
        return 'Préparée';
      case 'ENR':
        return 'Enregistrée';
      default:
        return 'Inconnu';
    }
  }

  Color getStatutColor(String code) {
    switch (code) {
      case 'EXP':
        return Colors.green;
      case 'ATT':
        return Colors.orange;
      case 'PRE':
        return Colors.blue;
      case 'ENR':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  bool isReservation(Map<String, dynamic> order) {
    return order['GP_LIBRETIERS1'] == 'S01';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes à traiter"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: fetchOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    "Erreur : $errorMessage",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : orders.isEmpty
                  ? const Center(child: Text("Aucune commande en attente."))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final isRes = isReservation(order);
                        final dateStr = order['GP_DATEPIECE'] ?? order['GP_DATECREATION'] ?? '';
                        final formattedDate = DateTime.tryParse(dateStr)?.toLocal().toString().split(' ')[0] ?? '';
                        final statutCode = order['GP_STATUTPIECE'] ?? 'ATT';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            title: Text(
                              isRes
                                  ? "Réservation ${order['GP_SOUCHE'] ?? ''}/${order['GP_NUMERO']}/${order['GP_INDICEG'] ?? ''}"
                                  : "Commande ${order['GP_NATUREPIECEG'] ?? ''}/${order['GP_SOUCHE'] ?? ''}/${order['GP_NUMERO']}/${order['GP_INDICEG'] ?? ''}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Date : $formattedDate"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatutColor(statutCode).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getStatutLabel(statutCode),
                                style: TextStyle(
                                  color: getStatutColor(statutCode),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
