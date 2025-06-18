import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/services/order_service.dart';
import 'package:project/services/storage_service.dart';

class TransfertListScreen extends StatefulWidget {
  const TransfertListScreen({super.key});

  @override
  State<TransfertListScreen> createState() => _TransfertListScreenState();
}

class _TransfertListScreenState extends State<TransfertListScreen> {
  List<Map<String, dynamic>> transferts = [];
  bool isLoading = true;
  String? errorMessage;

  String? userRole;
  String? userDepot;

  @override
  void initState() {
    super.initState();
    fetchAndLoad();
  }

  Future<void> fetchAndLoad() async {
    try {
      final user = await StorageService.getUserData();
      userRole = user['role'];
      userDepot = user['depot'];

      if (userDepot == null) {
        throw Exception("Dépôt utilisateur introuvable.");
      }

      // Appel avec le paramètre de filtre `depot`
      final data = await OrderService().fetchRecentTransfers(userDepot!);

      transferts = data;
    } catch (e) {
      errorMessage = e.toString();
    }
    setState(() => isLoading = false);
  }

  String formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final parsed = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demandes de Transfert"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text("Erreur : $errorMessage"))
              : transferts.isEmpty
                  ? const Center(child: Text("Aucune demande de transfert trouvée."))
                  : ListView.builder(
                      itemCount: transferts.length,
                      itemBuilder: (_, i) {
                        final t = transferts[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.compare_arrows, color: Colors.teal),
                            title: Text("Article: ${t['article']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Quantité: ${t['quantite']}"),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.store, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text("Destination: ${t['depotDestination'] ?? '-'}"),
                                  ],
                                ),
                                if (t['utilisateur'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("Par: ${t['utilisateur']}"),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("Date: ${formatDate(t['date'])}"),
                                ),
                              ],
                            ),
                            trailing: Text(
                              userRole == 'admin' ? 'Admin' : 'Magasinier',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
