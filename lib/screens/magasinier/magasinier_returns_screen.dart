import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';

class MagasinierReturnsScreen extends StatefulWidget {
  const MagasinierReturnsScreen({super.key});

  @override
  State<MagasinierReturnsScreen> createState() =>
      _MagasinierReturnsScreenState();
}

class _MagasinierReturnsScreenState extends State<MagasinierReturnsScreen> {
  List<Map<String, dynamic>> returns = [];
  bool isLoading = true;
  String? error;
  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '---';
    final dt = DateTime.tryParse(rawDate.toString());
    if (dt == null) return '---';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    fetchReturns();
  }

  Future<void> fetchReturns() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final res = await OrderService().fetchReturns();

      // ✅ Sort by date (assuming DATE_RETOUR is in ISO format)
      res.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['DATE_RETOUR'] ?? '') ?? DateTime(1970);
        final dateB =
            DateTime.tryParse(b['DATE_RETOUR'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      // ✅ Keep only the last 10
      setState(() {
        returns = res.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Retours Produits"),
        backgroundColor: Colors.orange.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Erreur: $error"))
              : returns.isEmpty
                  ? const Center(child: Text("Aucun retour trouvé."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: returns.length,
                      itemBuilder: (context, index) {
                        final r = returns[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.replay,
                                color: Colors.redAccent),
                            title: Text("Retour #${r['RETURN_ID'] ?? 'N/A'}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Client: ${r['TIERS'] ?? '---'}"),
                                Text("Date: ${_formatDate(r['DATE_RETOUR'])}"),
                                Text("Motif: ${r['MOTIF'] ?? 'Non précisé'}"),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to detailed return view
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
