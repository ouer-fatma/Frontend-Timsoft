import 'package:flutter/material.dart';
import 'package:project/services/home_service.dart';
import 'package:project/services/promotion_service.dart';

class ArticlePromotionScreen extends StatefulWidget {
  const ArticlePromotionScreen({super.key});

  @override
  State<ArticlePromotionScreen> createState() => _ArticlePromotionScreenState();
}

class _ArticlePromotionScreenState extends State<ArticlePromotionScreen> {
  final _remiseController = TextEditingController();
  final _promoService = PromotionService();
  final _articleService = ArticleService();

  List<Map<String, dynamic>> _articles = [];
  Map<String, dynamic>? _selectedArticle;
  String? _currentRemise;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final list = await _articleService.fetchArticles();
      setState(() => _articles = list);
    } catch (e) {
      _showSnack("Erreur chargement articles : $e", isError: true);
    }
  }

  Future<void> _loadPromo() async {
    if (_selectedArticle == null) return;
    setState(() => _loading = true);
    try {
      final list = await _promoService
          .getPromosByArticle(_selectedArticle!['GA_CODEARTICLE']);
      setState(() {
        _currentRemise = list.isNotEmpty ? list.first.gtrTypeRemise : null;
      });
    } catch (_) {
      setState(() => _currentRemise = null);
    }
    setState(() => _loading = false);
  }

  Future<void> _applyPromo() async {
    if (_selectedArticle == null || _remiseController.text.isEmpty) return;
    await _promoService.setPromoToArticle(
        _selectedArticle!['GA_CODEARTICLE'], _remiseController.text.trim());
    _loadPromo();
  }

  Future<void> _updatePromo() async {
    if (_selectedArticle == null || _remiseController.text.isEmpty) return;
    await _promoService.updatePromoForArticle(
        _selectedArticle!['GA_CODEARTICLE'], _remiseController.text.trim());
    _loadPromo();
  }

  Future<void> _deletePromo() async {
    if (_selectedArticle == null) return;
    await _promoService
        .deletePromoForArticle(_selectedArticle!['GA_CODEARTICLE']);
    _loadPromo();
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
      appBar: AppBar(title: const Text("Promotion par article")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedArticle,
              hint: const Text("Sélectionner un article"),
              items: _articles.map((article) {
                final code = article['GA_CODEARTICLE'];
                return DropdownMenuItem(
                  value: article,
                  child: Text(code),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedArticle = val);
                _loadPromo();
              },
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : Text(
                    _currentRemise != null
                        ? "Remise actuelle : $_currentRemise"
                        : "Aucune remise appliquée",
                    style: const TextStyle(fontSize: 16),
                  ),
            const SizedBox(height: 20),
            TextField(
              controller: _remiseController,
              decoration: const InputDecoration(
                labelText: "Saisir une remise personnalisée (ex: 10%)",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: _applyPromo, child: const Text("Créer")),
                ElevatedButton(
                    onPressed: _updatePromo, child: const Text("Modifier")),
                ElevatedButton(
                  onPressed: _deletePromo,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
