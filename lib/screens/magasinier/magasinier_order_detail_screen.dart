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
  bool isUpdating = false;

  static const String magasinierDepot = '004'; // à remplacer dynamiquement si besoin

  String get nature => widget.order['GP_NATUREPIECEG']?.toString() ?? 'BL';
  String get souche => widget.order['GP_SOUCHE']?.toString() ?? 'BL001';
  String get indice => widget.order['GP_INDICEG']?.toString() ?? '1';
  int get numero => int.tryParse(widget.order['GP_NUMERO'].toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchDetails();
    });
  }

  Future<void> fetchDetails() async {
    if (souche.isEmpty || indice.isEmpty || numero == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paramètres commande/réservation manquants")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final data = await OrderService().getOrderDetails(
        nature: nature,
        souche: souche,
        numero: numero,
        indice: indice,
      );
      setState(() {
        details = data;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement détails: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  void openPdf() async {
    try {
      final url = OrderService().getBLDownloadUrl(
        nature: nature,
        souche: souche,
        numero: numero,
        indice: indice,
        existing: true,
      );
      await OrderService().openPdfUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ouverture PDF: $e")),
      );
    }
  }

  Future<void> markAsExpedie() async {
    setState(() => isUpdating = true);
    try {
      await OrderService().updateOrderStatus(
        nature: nature,
        souche: souche,
        numero: numero,
        indice: indice,
        status: 'EXP',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Statut mis à jour.")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur mise à jour: $e")),
      );
    }
    setState(() => isUpdating = false);
  }

  Future<void> handleTransfert(String article, double quantiteDemandee) async {
  try {
    final depots = await OrderService().getDepotsDisponiblesPourArticleCommande(
      souche: widget.order['GP_SOUCHE'],
      numero: int.parse(widget.order['GP_NUMERO'].toString()),
      articleCode: article,
    );

    if (depots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun dépôt avec du stock disponible.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choisir un dépôt source"),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: depots.length,
            itemBuilder: (_, i) {
              final depot = depots[i];
              return ListTile(
                title: Text("Dépôt ${depot['depot']}"),
                subtitle: Text("Stock disponible: ${depot['quantite']}"),
                onTap: () async {
                  Navigator.pop(ctx);

                  try {
                    await OrderService().transferStock(
                      codeArticle: article,
                      quantite: quantiteDemandee,
                      depotSource: depot['depot'],
                      depotDestination: magasinierDepot,
                      reference: "Commande $numero",
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Transfert effectué")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur transfert: $e")),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur transfert: $e")));
  }
}

  @override
  Widget build(BuildContext context) {
    final commande = details?['commande'];
    final lignes = List<Map<String, dynamic>>.from(details?['lignes'] ?? []);
    final total = details?['TOTAL_APRES_REMISE'];

    return Scaffold(
      appBar: AppBar(
        title: Text(nature == 'CC' ? "Réservation à préparer" : "Commande à préparer"),
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
                  Text("Date: ${commande?['GP_DATECREATION'] ?? ''}"),
                  const Divider(height: 30),
                  const Text("Articles à préparer :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: lignes.isEmpty
                        ? const Center(child: Text("Aucun article trouvé."))
                        : ListView.builder(
                            itemCount: lignes.length,
                            itemBuilder: (context, index) {
                              final l = lignes[index];
                              final promo = l['PROMO'] ?? {};
                              final qte = (l['GL_QTEFACT'] is int)
                                  ? (l['GL_QTEFACT'] as int).toDouble()
                                  : double.tryParse(l['GL_QTEFACT'].toString()) ?? 0;

                              return Card(
                                child: ListTile(
                                  title: Text(l['GA_LIBELLE'] ?? 'Article'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Code: ${l['GL_ARTICLE']}"),
                                      if (promo['REMISE'] != null && promo['REMISE'] != '0%')
                                        Text("Remise: ${promo['REMISE']} (${promo['REMISE_MONTANT']} DT)"),
                                    ],
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("x$qte"),
                                      TextButton(
                                        onPressed: () => handleTransfert(l['GL_ARTICLE'], qte),
                                        child: const Text("Demande Transfert", style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (total != null) ...[
                    const SizedBox(height: 8),
                    Text("Total après remise : ${total.toString()} DT", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: lignes.isNotEmpty ? openPdf : null,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(nature == 'CC' ? "Voir Réservation (PDF)" : "Voir le BL (PDF)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: lignes.isNotEmpty && !isUpdating ? markAsExpedie : null,
                        icon: const Icon(Icons.check),
                        label: isUpdating
                            ? const Text("Mise à jour…")
                            : const Text("Expédier"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
