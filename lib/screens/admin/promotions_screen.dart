import 'package:flutter/material.dart';
import 'package:project/screens/admin/article_promotion_screen.dart';
import 'package:project/screens/admin/category_promotion_screen.dart';
import 'package:project/services/promotion_service.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _service = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _libelleController = TextEditingController();
  final _abregeController = TextEditingController();
  final _imprimableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      _promotions = await _service.fetchPromotions();
    } catch (e) {
      print('Erreur chargement : $e');
    }
    setState(() => _isLoading = false);
  }

  void _showForm({Promotion? promo}) {
    if (promo != null) {
      _codeController.text = promo.gtrTypeRemise;
      _libelleController.text = promo.libelle;
      _abregeController.text = promo.abrege;
      _imprimableController.text = promo.imprimable;
    } else {
      _codeController.clear();
      _libelleController.clear();
      _abregeController.clear();
      _imprimableController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(promo == null ? "Ajouter" : "Modifier"),
        content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Code'),
              validator: (v) => v!.isEmpty ? "Requis" : null,
              enabled: promo == null,
            ),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(labelText: 'Libellé'),
              validator: (v) => v!.isEmpty ? "Requis" : null,
            ),
            TextFormField(
              controller: _abregeController,
              decoration: const InputDecoration(labelText: 'Abrégé'),
            ),
            TextFormField(
              controller: _imprimableController,
              decoration: const InputDecoration(labelText: 'Imprimable'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final promoData = Promotion(
                gtrTypeRemise: _codeController.text,
                libelle: _libelleController.text,
                abrege: _abregeController.text,
                imprimable: _imprimableController.text,
              );
              try {
                if (promo == null) {
                  await _service.addPromotion(promoData);
                } else {
                  await _service.updatePromotion(
                      promo.gtrTypeRemise, promoData);
                }
                Navigator.pop(context);
                _loadPromotions();
              } catch (e) {
                print("Erreur ajout/modif : $e");
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Promotion promo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer la promotion '${promo.libelle}' ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer")),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deletePromotion(promo.gtrTypeRemise);
      _loadPromotions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Promos Catégorie',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CategoryPromotionScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: 'Promos Article',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ArticlePromotionScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _promotions.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) {
                final promo = _promotions[index];
                return ListTile(
                  title: Text(promo.libelle),
                  subtitle: Text(
                      "Code: ${promo.gtrTypeRemise} - Abrégé: ${promo.abrege}"),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(promo: promo)),
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(promo)),
                  ]),
                );
              },
            ),
    );
  }
}
