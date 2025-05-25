import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';

class MagasinierOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const MagasinierOrderDetailScreen({super.key, required this.order});

  @override
  State<MagasinierOrderDetailScreen> createState() => _MagasinierOrderDetailScreenState();
}

class _MagasinierOrderDetailScreenState extends State<MagasinierOrderDetailScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    try {
      final data = await OrderService().getOrderDetails(
        nature: widget.order['GP_NATUREPIECEG'].toString(),
        souche: widget.order['GP_SOUCHE'].toString(),
        numero: int.parse(widget.order['GP_NUMERO'].toString()),
        indice: widget.order['GP_INDICEG'].toString(),
      );
      setState(() {
        details = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement détails: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commande = details?['commande'];
    final lignes = List<Map<String, dynamic>>.from(details?['lignes'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Commande à préparer"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Client: ${commande?['GP_TIERS'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Date: ${commande?['GP_DATECREATION']}"),
                  const Divider(height: 30),
                  const Text("Articles à préparer :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lignes.length,
                      itemBuilder: (context, index) {
                        final l = lignes[index];
                        return Card(
                          child: ListTile(
                            title: Text(l['GA_LIBELLE'] ?? 'Article'),
                            subtitle: Text("Code: ${l['GL_ARTICLE']}"),
                            trailing: Text("x${l['GL_QTEFACT']}"),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Ajouter action "Marquer comme expédiée"
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fonctionnalité à implémenter : marquer comme expédiée.")),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Marquer comme expédiée"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  )
                ],
              ),
            ),
    );
  }
}
