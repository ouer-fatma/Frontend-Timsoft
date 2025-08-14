import 'package:flutter/material.dart';
import 'package:project/models/RemiseType.dart';
import 'package:project/services/promotion_service.dart';

class CategoryPromotionScreen extends StatefulWidget {
  const CategoryPromotionScreen({super.key});

  @override
  State<CategoryPromotionScreen> createState() =>
      _CategoryPromotionScreenState();
}

class _CategoryPromotionScreenState extends State<CategoryPromotionScreen> {
  final _service = PromotionService();

  List<String> _categories = [];
  List<RemiseType> _remiseTypes = [];
  RemiseType? _selectedRemiseType;

  List<Promotion> _promos = [];

  String? _selectedCategory;

  bool _loading = false;
  bool _initLoading = true;

  Map<String, List<Promotion>> _promoByCategory = {};
  bool _loadingDrawer = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final cats = await _service.fetchCategories();
      final remises = await _service.fetchRemiseTypes();
      setState(() {
        _categories = cats.where((e) => e.trim().isNotEmpty).toList();
        _remiseTypes = remises;
        _initLoading = false;
      });
    } catch (e) {
      _showSnack("Erreur chargement données: $e", isError: true);
      setState(() => _initLoading = false);
    }
  }

  Future<void> _loadPromo() async {
    if (_selectedCategory == null) return;
    setState(() {
      _loading = true;
      _promos = [];
    });
    try {
      final list = await _service.getPromosByCategory(_selectedCategory!);
      setState(() => _promos = list);
    } catch (_) {
      setState(() => _promos = []);
    }
    setState(() => _loading = false);
  }

  Future<void> _loadAllCategoryPromos() async {
    setState(() => _loadingDrawer = true);
    try {
      final data = await _service.getAllCategoryPromos();
      setState(() {
        _promoByCategory = data;
        _loadingDrawer = false;
      });
    } catch (e) {
      _showSnack("Erreur chargement liste : $e", isError: true);
      setState(() => _loadingDrawer = false);
    }
  }

  Future<void> _applyPromo() async {
    if (_selectedCategory == null || _selectedRemiseType == null) return;
    try {
      await _service.setPromoToCategory(
          _selectedCategory!, _selectedRemiseType!.id);

      _showSnack("Promotion créée avec succès");
      _loadPromo();
    } catch (e) {
      _showSnack("Erreur création promo : $e", isError: true);
    }
  }

  Future<void> _updatePromo() async {
    if (_selectedCategory == null || _selectedRemiseType == null) return;
    try {
      await _service.updatePromoForCategory(
          _selectedCategory!, _selectedRemiseType!.id);
      _showSnack("Promotion modifiée");
      _loadPromo();
    } catch (e) {
      _showSnack("Erreur mise à jour : $e", isError: true);
    }
  }

  Future<void> _deletePromo() async {
    if (_selectedCategory == null) return;
    try {
      await _service.deletePromoForCategory(_selectedCategory!);
      _showSnack("Promotion supprimée");
      _loadPromo();
    } catch (e) {
      _showSnack("Erreur suppression : $e", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final snack = SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promo Catégorie"),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: "Voir toutes les promotions",
              onPressed: () async {
                await _loadAllCategoryPromos();
                Scaffold.of(ctx).openEndDrawer(); // ✅ Contexte valide ici
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: _loadingDrawer
              ? const Center(child: CircularProgressIndicator())
              : _promoByCategory.isEmpty
                  ? const Center(child: Text("Aucune promotion trouvée"))
                  : ListView.builder(
                      itemCount: _promoByCategory.keys.length,
                      itemBuilder: (context, index) {
                        final cat = _promoByCategory.keys.elementAt(index);
                        final promos = _promoByCategory[cat]!;
                        return ListTile(
                          title: Text("Catégorie : $cat"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: promos
                                .map((p) => Text("- ${p.gtrTypeRemise}"))
                                .toList(),
                          ),
                        );
                      },
                    ),
        ),
      ),
      body: _initLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: "Catégorie"),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _promos = [];
                      });
                      _loadPromo();
                    },
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _promos.isEmpty
                          ? const Text("Aucune promotion pour cette catégorie.")
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _promos
                                  .map((p) => Text("Promo: ${p.gtrTypeRemise}",
                                      style: const TextStyle(fontSize: 16)))
                                  .toList(),
                            ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<RemiseType>(
                    value: _selectedRemiseType,
                    decoration:
                        const InputDecoration(labelText: "Type de remise"),
                    items: _remiseTypes
                        .map((rem) => DropdownMenuItem(
                              value: rem,
                              child: Text(rem.libelle),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedRemiseType = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                          onPressed: (_selectedCategory != null &&
                                  _selectedRemiseType != null)
                              ? _applyPromo
                              : null,
                          child: const Text("Créer")),
                      ElevatedButton(
                          onPressed: (_selectedCategory != null &&
                                  _selectedRemiseType != null)
                              ? _updatePromo
                              : null,
                          child: const Text("Modifier")),
                      ElevatedButton(
                        onPressed:
                            _selectedCategory != null ? _deletePromo : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text("Supprimer"),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
