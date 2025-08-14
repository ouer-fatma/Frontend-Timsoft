import 'package:flutter/material.dart';
import 'package:project/services/panier_local_service.dart';
import 'package:project/services/panier_service.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/services/dimension_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/utils/color_mapper.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;
  final List<Map<String, dynamic>> allVariants;

  const ArticleDetailScreen({
    super.key,
    required this.article,
    required this.allVariants,
  });

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
    if (_dimensions.isEmpty) {
      selectedDim1 = ' ';
      selectedDim2 = ' ';
      loadQuantite();
    }
  }

  Future<void> loadUserData() async {
    final userData = await StorageService.getUserData();
    setState(() {
      codeTiers = userData?['codeTiers'] ?? "GUEST"; // ✅ null-safe
    });
  }

  Future<void> loadDimensions() async {
    final variantesRaw = widget.article['variantes'];
    if (variantesRaw == null || variantesRaw is! List) {
      setState(() => _isLoadingDimensions = false);
      return;
    }

    final variantes = variantesRaw.cast<Map<String, dynamic>>();
    final tailles = <String>{};
    final couleurs = <String>{};

    for (final v in variantes) {
      final taille = v['taille']?.toString().trim();
      final couleur = v['couleur']?.toString().trim();

      if (taille != null && taille.isNotEmpty) tailles.add(taille);
      if (couleur != null && couleur.isNotEmpty) couleurs.add(couleur);
    }

    setState(() {
      _dimensions = [
        ...tailles.map((t) => {'type': 'DI1', 'libelle': t}),
        ...couleurs.map((c) => {'type': 'DI2', 'libelle': c}),
      ];
      _isLoadingDimensions = false;
    });
    if (tailles.isEmpty && couleurs.isEmpty) {
      // ✅ Auto-remplir dim1/dim2 avec des espaces si aucune dimension n'existe
      setState(() {
        selectedDim1 = ' ';
        selectedDim2 = ' ';
      });
      loadQuantite(); // Charger stock immédiatement
    }
  }

  Future<void> loadQuantite() async {
    setState(() => _isLoadingQuantite = true);

    final codeArticle =
        widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE'];

    // Utiliser des valeurs vides si dimensions absentes
    final dim1 = selectedDim1 ?? '';
    final dim2 = selectedDim2 ?? '';

    // Si les dimensions sont vides, on envoie un espace
    final dim1Final = dim1.isEmpty ? ' ' : dim1;
    final dim2Final = dim2.isEmpty ? ' ' : dim2;

    final uri = Uri.parse(
      'http://localhost:3000/articles/$codeArticle/quantite/$dim1Final/$dim2Final',
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

  Future<void> _handleAddToCart() async {
    setState(() => _isLoading = true);
    try {
      String getCodeArticle() {
        final hasDimensions = widget.allVariants.isNotEmpty;
        if (!hasDimensions) return widget.article['GA_CODEARTICLE'];

        final match = widget.allVariants.firstWhere(
          (v) =>
              (v['taille']?.toString()?.trim() == selectedDim1) &&
              (v['couleur']?.toString()?.trim() == selectedDim2),
          orElse: () => {},
        );

        return match['GA_CODEARTICLE'] ?? widget.article['GA_CODEARTICLE'];
      }

      // 🟡 Ajoute tes logs ici
      print("👉 AJOUT AU PANIER:");
      print("codeTiers: $codeTiers");
      print("codeArticle: ${getCodeArticle()}");
      print("dim1: ${selectedDim1 ?? 'null'}");
      print("dim2: ${selectedDim2 ?? 'null'}");

      if (codeTiers == "GUEST") {
        final article = {
          "GL_ARTICLE": getCodeArticle(),
          "GA_LIBELLE": widget.article['GA_LIBELLE'] ?? '',
          "GA_PVTTC": widget.article['GA_PVTTC'] ?? 0.0,
          "GL_QTEFACT": quantiteSouhaitee,
          "dim1Libelle": selectedDim1,
          "dim2Libelle": selectedDim2,
          "GL_CODESDIM": "$selectedDim1-$selectedDim2",
          "TotalLigne": quantiteSouhaitee * (widget.article['GA_PVTTC'] ?? 0.0),
        };

        await PanierLocalService.addArticle(article);
      } else {
        // ✅ On force " " si dim1 ou dim2 sont absents
        final dim1 =
            selectedDim1?.trim().isNotEmpty == true ? selectedDim1! : ' ';
        final dim2 =
            selectedDim2?.trim().isNotEmpty == true ? selectedDim2! : ' ';
        await _panierService.ajouterAuPanier(
          codeArticle: getCodeArticle(),
          quantite: quantiteSouhaitee.toDouble(),
          dim1: dim1,
          dim2: dim2,
        );
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop();
          });
          return AlertDialog(
            backgroundColor: Colors.green[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Ajouté au panier avec succès !",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> getValuesForType(String type) {
    return _dimensions
        .where((dim) => dim['type'] == type)
        .map((dim) => dim['libelle']!)
        .toSet()
        .toList();
  }

  Widget _buildArticleImage(Map<String, dynamic> article) {
    final rawImage = article['image'] ?? article['GA_IMAGE_BASE64'];

    if (rawImage != null && rawImage is String) {
      try {
        if (rawImage.startsWith('data:image')) {
          final base64Str = rawImage.split(',').last;
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 100),
          );
        }
      } catch (e) {
        print("Erreur de décodage d'image base64: $e");
      }
    }

    return const Icon(Icons.image_not_supported, size: 100);
  }

  @override
  Widget build(BuildContext context) {
    final dim1Values = getValuesForType('DI1');
    final dim2Values = getValuesForType('DI2');
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
        title: const Text("Détail de l'article"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 1,
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildArticleImage(widget.article),
                    ),
                  ),
                ),
                const SizedBox(width: 24, height: 24),
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article['GA_LIBELLE'] ?? '',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("€${widget.article['GA_PVTTC']}",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      const SizedBox(height: 24),

                      // TAILLE
                      if (dim1Values.isNotEmpty) ...[
                        const Text("Taille",
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: dim1Values.map((value) {
                            return ChoiceChip(
                              label: Text(value),
                              selected: selectedDim1 == value,
                              onSelected: (_) {
                                setState(() {
                                  selectedDim1 = value;
                                  quantiteDisponible = null;
                                });
                                loadQuantite();
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // COULEUR
                      if (dim2Values.isNotEmpty) ...[
                        const Text("Couleur",
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: dim2Values.map((value) {
                            final isSelected = selectedDim2 == value;
                            final color = mapColorNameToColor(value);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDim2 = value;
                                  quantiteDisponible = null;
                                });
                                loadQuantite();
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (selectedDim2 != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text("Couleur sélectionnée : $selectedDim2",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // QUANTITÉ DISPONIBLE
                      if (_isLoadingQuantite)
                        const CircularProgressIndicator()
                      else if (quantiteDisponible != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: quantiteDisponible == 0
                                ? Colors.red[100]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            quantiteDisponible == 0
                                ? "Rupture de stock"
                                : "En stock : $quantiteDisponible",
                            style: TextStyle(
                              color: quantiteDisponible == 0
                                  ? Colors.red[800]
                                  : Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // CHOIX DE QUANTITÉ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text("Quantité : ",
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: quantiteSouhaitee > 1
                                ? () => setState(() => quantiteSouhaitee--)
                                : null,
                          ),
                          Text('$quantiteSouhaitee',
                              style: const TextStyle(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: (quantiteDisponible != null &&
                                    quantiteSouhaitee < quantiteDisponible!)
                                ? () => setState(() => quantiteSouhaitee++)
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // AJOUTER AU PANIER
                      SizedBox(
                        width: double.infinity,
                        child: Builder(
                          builder: (context) {
                            final hasDim1 =
                                _dimensions.any((d) => d['type'] == 'DI1');
                            final hasDim2 =
                                _dimensions.any((d) => d['type'] == 'DI2');
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text("Ajouter au panier",
                                  style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B5BDB),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: (_isLoading ||
                                      quantiteDisponible == null ||
                                      quantiteDisponible == 0 ||
                                      (hasDim1 && selectedDim1 == null) ||
                                      (hasDim2 && selectedDim2 == null) ||
                                      quantiteSouhaitee >
                                          (quantiteDisponible ?? 0))
                                  ? null
                                  : () async {
                                      await _handleAddToCart();
                                    },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        "Référence : ${widget.article['GA_CODEARTICLE1'] ?? widget.article['GA_CODEARTICLE']}",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      if (codeTiers == "GUEST") ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Connectez-vous pour finaliser votre commande plus tard.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
