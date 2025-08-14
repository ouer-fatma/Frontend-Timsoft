import 'package:flutter/material.dart';
import 'package:project/services/promotion_service.dart';

class ClientPromotionsScreen extends StatefulWidget {
  const ClientPromotionsScreen({super.key});

  @override
  State<ClientPromotionsScreen> createState() => _ClientPromotionsScreenState();
}

class _ClientPromotionsScreenState extends State<ClientPromotionsScreen> {
  final PromotionService _service = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();  
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final promos = await _service.fetchPromotions();
      setState(() {
        _promotions = promos;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement : $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Promotions Actuelles")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? const Center(child: Text("Aucune promotion pour le moment."))
              : ListView.separated(
                  itemCount: _promotions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final promo = _promotions[index];
                    return ListTile(
                      title: Text(promo.libelle),
                      subtitle: Text("Code: ${promo.gtrTypeRemise}"),
                      trailing: Text(promo.imprimable),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(promo.libelle),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Abrégé : ${promo.abrege}"),
                                Text("Code : ${promo.gtrTypeRemise}"),
                                Text("Imprimable : ${promo.imprimable}"),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Fermer"))
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
