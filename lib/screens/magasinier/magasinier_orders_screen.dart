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

  String selectedStatut = 'ENR';

  final Map<String, String> statutLabels = {
    'ENR': 'Enregistrées',
    'PRE': 'Prêtes',
    'EXP': 'Expédiées',
    'LIV': 'Livrées',
    'RES': 'Réservations',
  };

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
      List<Map<String, dynamic>> result;

      switch (selectedStatut) {
        case 'ENR': // Mode livraison
          result = await _orderService.fetchOrdersLivraison();
          break;
        case 'RES': // Mode retrait magasin
          result = await _orderService.fetchOrdersRetrait();
          break;
        case 'PRE':
          result = await _orderService.fetchOrdersPretes();
          break;
        case 'EXP':
          result = await _orderService.fetchOrdersExpediees();
          break;
        case 'LIV':
          result = await _orderService.fetchOrdersLivrees();
          break;
        default:
          result = [];
      }

      result.sort((a, b) {
        final dateA = DateTime.tryParse(
                a['GP_DATEPIECE'] ?? a['GP_DATECREATION'] ?? '') ??
            DateTime(1970);
        final dateB = DateTime.tryParse(
                b['GP_DATEPIECE'] ?? b['GP_DATECREATION'] ?? '') ??
            DateTime(1970);
        return dateB.compareTo(dateA);
      });

      setState(() {
        orders = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erreur : ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Widget buildStatutDropdown() {
    return DropdownButton<String>(
      value: selectedStatut,
      dropdownColor: Colors.white,
      underline: const SizedBox(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedStatut = value;
          });
          fetchOrders();
        }
      },
      items: statutLabels.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );
  }

  String getStatutLabel(String code) {
    switch (code) {
      case 'EXP':
        return 'Expédiée';
      case 'PRE':
        return 'Préparée';
      case 'RES':
        return 'Retrait';
      case 'ENR':
        return 'Livraison';
      case 'LIV':
        return 'Livrée';
      default:
        return 'Inconnu';
    }
  }

  Color getStatutColor(String code) {
    switch (code) {
      case 'EXP':
        return Colors.green;
      case 'PRE':
        return Colors.blue;
      case 'RES':
        return Colors.purple;
      case 'ENR':
        return Colors.teal;
      case 'LIV':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  bool isReservation(Map<String, dynamic> order) {
    return selectedStatut == 'RES';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes Magasinier"),
        backgroundColor: Colors.teal,
        actions: [
          buildStatutDropdown(),
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
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : orders.isEmpty
                  ? const Center(child: Text("Aucune commande trouvée."))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final isRes = isReservation(order);
                        final dateStr = order['GP_DATEPIECE'] ??
                            order['GP_DATECREATION'] ??
                            '';
                        final formattedDate = DateTime.tryParse(dateStr)
                                ?.toLocal()
                                .toString()
                                .split(' ')[0] ??
                            '';
                        final statutCode = order['GP_STATUTPIECE'] ?? 'ENR';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            title: Text(
                              isRes
                                  ? "Retrait ${order['GP_SOUCHE']}/${order['GP_NUMERO']}/${order['GP_INDICEG']}"
                                  : "Livraison ${order['GP_SOUCHE']}/${order['GP_NUMERO']}/${order['GP_INDICEG']}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Date : $formattedDate"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    getStatutColor(statutCode).withOpacity(0.2),
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
                                  builder: (_) =>
                                      MagasinierOrderDetailScreen(order: order),
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
