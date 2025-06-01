import 'package:flutter/material.dart';
import 'package:project/services/panier_service.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/services/dimension_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final PanierService _panierService = PanierService();
  final DimensionService _dimensionService = DimensionService();

  String? codeTiers;
  bool _isLoading = false;
  bool _isLoadingDimensions = true;
  bool _isLoadingQuantite = false;

  List<Map<String, String>> _dimensions = [];
  String? selectedDim1;
  String? selectedDim2;
  int? quantiteDisponible;
  int quantiteSouhaitee = 1;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadDimensions();
  }

  Future<void> loadUserData() async {
    final userData = await StorageService.getUserData();
    setState(() {
      codeTiers = userData['codeTiers'];
    });
  }

  Future<void> loadDimensions() async {
    final codeArticle = widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE'];
    if (codeArticle == null) {
      print("❌ Aucun code article pour charger les dimensions.");
      setState(() => _isLoadingDimensions = false);
      return;
    }

    try {
      final dims = await _dimensionService.getDimensions(codeArticle);
      setState(() {
        _dimensions = dims;
        _isLoadingDimensions = false;
      });
    } catch (e) {
      setState(() => _isLoadingDimensions = false);
      print("Erreur chargement dimensions: $e");
    }
  }

  Future<void> loadQuantite() async {
    if (selectedDim1 == null || selectedDim2 == null) return;

    setState(() => _isLoadingQuantite = true);
    final codeArticle = widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE'];
    final uri = Uri.parse(
      'http://localhost:3000/articles/$codeArticle/details?dim1=$selectedDim1&dim2=$selectedDim2',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quantiteDisponible = data['quantite'] ?? 0;
          quantiteSouhaitee = 1;
        });
      } else {
        setState(() => quantiteDisponible = 0);
      }
    } catch (e) {
      setState(() => quantiteDisponible = 0);
      print('Erreur quantite: $e');
    } finally {
      setState(() => _isLoadingQuantite = false);
    }
  }

  List<String> getValuesForType(String type) {
    return _dimensions
        .where((dim) => dim['type'] == type)
        .map((dim) => dim['libelle']!)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final dim1Values = getValuesForType('DI1');
    final dim2Values = getValuesForType('DI2');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article['GA_LIBELLE'] ?? 'Détail Article'),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.article['GA_IMAGE_URL'] != null
                    ? Image.network(
                        widget.article['GA_IMAGE_URL'],
                        fit: BoxFit.cover,
                        height: 400,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                      )
                    : const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.article['GA_LIBELLE'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Code: ${widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE']}"),
                  const SizedBox(height: 8),
                  Text("Prix TTC: €${widget.article['GA_PVTTC']}", style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),

                  DropdownButton<String>(
                    hint: const Text("Sélectionnez la taille"),
                    value: selectedDim1,
                    items: dim1Values.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDim1 = val;
                        quantiteDisponible = null;
                      });
                      loadQuantite();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButton<String>(
                    hint: const Text("Sélectionnez la couleur"),
                    value: selectedDim2,
                    items: dim2Values.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDim2 = val;
                        quantiteDisponible = null;
                      });
                      loadQuantite();
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingQuantite)
                    const CircularProgressIndicator()
                  else if (quantiteDisponible != null)
                    Text("Quantité disponible : $quantiteDisponible", style: const TextStyle(color: Colors.green)),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Quantité : "),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantiteSouhaitee > 1
                            ? () {
                                setState(() {
                                  quantiteSouhaitee--;
                                });
                              }
                            : null,
                      ),
                      Text('$quantiteSouhaitee', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: (quantiteDisponible != null && quantiteSouhaitee < quantiteDisponible!)
                            ? () {
                                setState(() {
                                  quantiteSouhaitee++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  codeTiers != null
                      ? ElevatedButton.icon(
                          onPressed: (_isLoading ||
    quantiteDisponible == null ||
    quantiteDisponible == 0 ||
    selectedDim1 == null ||
    selectedDim2 == null ||
    quantiteSouhaitee > quantiteDisponible!)
  ? null
  : () async {
      setState(() => _isLoading = true);
      try {
        await _panierService.ajouterAuPanier(
          codeTiers: codeTiers!,
          codeArticle: widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE'],
          quantite: quantiteSouhaitee.toDouble(),
          dim1Libelle: selectedDim1!,
          dim2Libelle: selectedDim2!,
          grilleDim1: widget.article['GA_GRILLEDIM1'],
          grilleDim2: widget.article['GA_GRILLEDIM2'],
        );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Ajouté au panier !")),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Erreur: $e")),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Ajouter au panier"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5BDB),
                            foregroundColor: Colors.white,
                          ),
                        )
                      : const Text("Connectez-vous pour ajouter au panier", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
