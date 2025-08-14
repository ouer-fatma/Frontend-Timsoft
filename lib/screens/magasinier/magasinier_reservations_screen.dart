import 'package:flutter/material.dart';
import 'package:project/screens/magasinier/magasinier_order_detail_screen.dart';
import 'package:project/services/order_service.dart';

class MagasinierReservationsScreen extends StatefulWidget {
  const MagasinierReservationsScreen({super.key});

  @override
  State<MagasinierReservationsScreen> createState() =>
      _MagasinierReservationsScreenState();
}

class _MagasinierReservationsScreenState
    extends State<MagasinierReservationsScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> reservations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _orderService.fetchReservationsPourMagasinier();

      data.sort((a, b) {
        final dateA = DateTime.tryParse(
                a['GP_DATEPIECE'] ?? a['GP_DATECREATION'] ?? '') ??
            DateTime(1970);
        final dateB = DateTime.tryParse(
                b['GP_DATEPIECE'] ?? b['GP_DATECREATION'] ?? '') ??
            DateTime(1970);
        return dateB.compareTo(dateA);
      });

      setState(() {
        reservations = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erreur : ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Color getStatutColor(String code) {
    switch (code) {
      case 'EXP':
        return Colors.green;
      case 'PRE':
        return Colors.blue;
      case 'ENR':
        return Colors.teal;
      case 'LIV':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getStatutLabel(String code) {
    switch (code) {
      case 'EXP':
        return 'Expédiée';
      case 'PRE':
        return 'Préparée';
      case 'ENR':
        return 'Enregistrée';
      case 'LIV':
        return 'Livrée';
      default:
        return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Réservations à traiter"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchReservations,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : reservations.isEmpty
                  ? const Center(child: Text("Aucune réservation disponible."))
                  : ListView.builder(
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        final order = reservations[index];
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
                              "Réservation ${order['GP_SOUCHE']}/${order['GP_NUMERO']}/${order['GP_INDICEG']}",
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
