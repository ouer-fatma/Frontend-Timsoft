// ✅ Version modifiée du HomeScreen pour un utilisateur connecté
import 'package:flutter/material.dart';
import 'package:project/main.dart';
import 'package:project/screens/User/article_detail_screen.dart';
import 'package:project/screens/User/client_notifications_screen.dart';
import 'package:project/screens/User/user_profile_screen.dart';
import 'package:project/screens/User/familles_screen.dart';
import 'package:project/screens/User/user_orders_screen.dart';
import 'package:project/screens/User/ValidationCommandeScreen.dart';
import 'package:project/screens/User/client_promotions_screen.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/panier_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  final String userNom;
  final String userEmail;
  final String userRole;
  const HomeScreen({
    super.key,
    required this.userNom,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? userEmail;
  String? codeTiers;
  bool isLoading = true;

  final List<String> placeholderImages = [
    'assets/articles/Blouse.jpg',
    'assets/articles/chemise.jpg',
    'assets/articles/Pull.jpg',
    'assets/articles/Sweat.jpg',
  ];
  List<dynamic> articles = [];
  final TextEditingController _searchController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    userName = widget.userNom;
    userEmail = widget.userEmail;
    loadUserData();
    fetchArticles();
    _initFCM(); // 🆕 Notification Firebase
  }

  Future<void> loadUserData() async {
    final token = await StorageService.getToken();
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        codeTiers = decoded['codeTiers'];
      });
    }
  }

  Future<void> _initFCM() async {
    // 1. Requête permission pour iOS
    await _firebaseMessaging.requestPermission();

    // 2. Init local notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 3. Gère les messages reçus en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );

        // ✅ Ajoute dans la liste locale
        NotificationService.notify({
          'title': notification.title,
          'message': notification.body,
          'date': DateTime.now().toIso8601String(),
        });
      }
    });

    // 4. (optionnel) Affiche le token dans la console
    String? token = await _firebaseMessaging.getToken();
    print("📲 FCM Token: $token");
  }

  Future<void> fetchArticles() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/articles'));
      if (response.statusCode == 200) {
        setState(() {
          articles = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur fetch: $e");
    }
    setState(() => isLoading = false);
  }

  void openFamillesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.65,
          child: Material(
            borderRadius: BorderRadius.circular(12),
            child: FamillesScreen(),
          ),
        ),
      ),
    );
  }

  void showSearchOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Recherche",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close, size: 28),
                          ),
                          const Text("Fermer", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Chercher un produit",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onSubmitted: (value) async {
                          if (value.isNotEmpty) {
                            Navigator.of(context).pop();
                            await searchArticles(value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Dernières recherches :",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          _suggestionChip("pull"),
                          _suggestionChip("sweat"),
                          _suggestionChip("robe"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _suggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.of(context).pop();
        searchArticles(label);
      },
    );
  }

  Future<void> searchArticles(String query) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/articles/search/$query'));
      if (response.statusCode == 200) {
        setState(() {
          articles = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Erreur lors de la recherche: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  void _showCartSidePanelClient(BuildContext context) async {
    final userData = await StorageService.getUserData();
    final codeTiers = userData?['codeTiers'] ?? 'GUEST';

    final panierService = PanierService();
    List<dynamic> lignes = [];
    List<Map<String, dynamic>> depots = [];
    bool isRetrait = false;
    String? selectedDepot;
    bool isLoading = true;
    bool hasFetched = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> fetchPanier() async {
              setState(() => isLoading = true);
              try {
                lignes = await panierService.getPanier(codeTiers: codeTiers);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Erreur: $e")));
              }
              setState(() => isLoading = false);
            }

            void initFetch() {
              if (!hasFetched) {
                hasFetched = true;
                fetchPanier();
              }
            }

            Future<void> fetchDepots() async {
              try {
                final res = await http.get(
                    Uri.parse("http://localhost:3000/click-collect/depots"));
                if (res.statusCode == 200) {
                  depots = jsonDecode(res.body).cast<Map<String, dynamic>>();
                  setState(() {});
                }
              } catch (e) {
                print("Erreur dépôts: $e");
              }
            }

            Future<void> supprimerArticle(
                String codeArticle, String codeSDIM) async {
              try {
                await panierService.retirerDuPanier(
                  codeTiers: codeTiers,
                  codeArticle: codeArticle,
                  codesdim: codeSDIM,
                );
                setState(() {
                  lignes.removeWhere((l) =>
                      l['GL_ARTICLE'] == codeArticle &&
                      l['GL_CODESDIM'] == codeSDIM);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Article supprimé.")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur suppression: $e")));
              }
            }

            Future<void> validerCommande() async {
              final token = await StorageService.getToken();
              if (JwtDecoder.isExpired(token!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Session expirée.")),
                );
                return;
              }

              final decoded = JwtDecoder.decode(token);
              final codeTiers = decoded['codeTiers'];
              if (codeTiers == null) return;

              if (isRetrait && selectedDepot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Choisissez un dépôt.")));
                return;
              }

              try {
                final res = await http.get(
                  Uri.parse("http://localhost:3000/orders/next-numero"),
                  headers: {"Authorization": "Bearer $token"},
                );

                if (res.statusCode != 200) throw Exception("Erreur numéro");

                final numero = jsonDecode(res.body)['nextNumero'];
                final now = DateTime.now().toUtc().toIso8601String();

                final body = {
                  "GP_NATUREPIECEG": "CC",
                  "GP_SOUCHE": "04",
                  "GP_NUMERO": numero,
                  "GP_INDICEG": 1,
                  "GP_DATECREATION": now,
                  "GP_LIBRETIERS1": isRetrait ? "S01" : "LOC",
                  "GP_DEPOT": isRetrait ? selectedDepot : null,
                };

                final postRes = await http.post(
                  Uri.parse("http://localhost:3000/orders"),
                  headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer $token"
                  },
                  body: jsonEncode(body),
                );

                if (postRes.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("✅ Commande enregistrée avec succès.")),
                  );
                  setState(() => lignes.clear());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur: ${postRes.body}")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text("Erreur: $e")));
              }
            }

            initFetch();

            double total = lignes.fold(
                0.0, (sum, item) => sum + (item['TotalLigne'] ?? 0.0));

            return Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Material(
                  color: Colors.white,
                  elevation: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mon panier",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : lignes.isEmpty
                                  ? const Center(
                                      child: Text("Votre panier est vide."))
                                  : ListView.builder(
                                      itemCount: lignes.length,
                                      itemBuilder: (_, index) {
                                        final l = lignes[index];
                                        return ListTile(
                                          leading:
                                              const Icon(Icons.shopping_bag),
                                          title: Text(
                                              l['GA_LIBELLE'] ?? 'Article'),
                                          subtitle: Text(
                                              "Qté: ${l['GL_QTEFACT']} - Taille: ${l['dim1Libelle'] ?? '-'} - Couleur: ${l['dim2Libelle'] ?? '-'}"),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  "€${(l['TotalLigne'] ?? 0.0).toStringAsFixed(2)}"),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    supprimerArticle(
                                                        l['GL_ARTICLE'],
                                                        l['GL_CODESDIM']),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        SwitchListTile(
                          title: const Text("Retrait en dépôt"),
                          value: isRetrait,
                          onChanged: (val) {
                            setState(() {
                              isRetrait = val;
                              if (val) {
                                selectedDepot = null;
                                fetchDepots();
                              }
                            });
                          },
                        ),
                        if (isRetrait)
                          depots.isNotEmpty
                              ? DropdownButtonFormField<String>(
                                  value: depots.any(
                                          (d) => d['code'] == selectedDepot)
                                      ? selectedDepot
                                      : null,
                                  decoration: const InputDecoration(
                                      labelText: "Choisissez un dépôt"),
                                  items: depots.map((depot) {
                                    return DropdownMenuItem<String>(
                                      value: depot['code'],
                                      child: Text(depot['libelle'] ?? 'Dépôt'),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedDepot = val),
                                )
                              : const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text("Aucun dépôt disponible."),
                                ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total :",
                                style: TextStyle(fontSize: 16)),
                            Text("€${total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ValidationCommandeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text("Valider la commande"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5BDB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Fermer"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 160,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed =
                    constraints.biggest.height <= kToolbarHeight + 10;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: isCollapsed
                        ? const Border(
                            bottom: BorderSide(color: Colors.black12))
                        : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: openFamillesDialog,
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/logo.png',
                          height: MediaQuery.of(context).size.width > 800
                              ? 100
                              : 80,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.local_offer_outlined,
                              color: Colors.red),
                          tooltip: 'Promotions',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ClientPromotionsScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          tooltip: 'Notifications',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ClientNotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Recherche',
                          onPressed: () {
                            showSearchOverlay(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => _showCartSidePanelClient(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userName: userName ?? '',
                                  userEmail: userEmail ?? '',
                                  userRole: widget.userRole,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.receipt_long),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserOrdersScreen(
                                    codeTiers: codeTiers ?? ''),
                              ),
                            );
                          },
                        ),
                        TextButton(
                          onPressed: () async {
                            await StorageService.clearToken();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text("Se déconnecter"),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                AnimatedTextKit(
                  isRepeatingAnimation: false,
                  totalRepeatCount: 1,
                  animatedTexts: [
                    TyperAnimatedText(
                      'Votre partenaire pour une expérience de mode réinventée',
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w400),
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (userName != null)
                  Text(
                    'Bienvenue, $userName',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final article = articles[index];
                        final image =
                            placeholderImages[index % placeholderImages.length];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  final codeArticle = article['GA_CODEARTICLE'];

                                  final variants = articles
                                      .where((a) =>
                                          a['GA_CODEARTICLE'] == codeArticle)
                                      .cast<Map<String, dynamic>>()
                                      .toList();

                                  return ArticleDetailScreen(
                                    article: article,
                                    allVariants:
                                        List<Map<String, dynamic>>.from(
                                            article['variantes'] ?? []),
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: article['GA_IMAGE_BASE64'] != null
                                      ? Image.memory(
                                          base64Decode(
                                              article['GA_IMAGE_BASE64']
                                                  .split(',')
                                                  .last),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                            image,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          image,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article['GA_LIBELLE'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Code: ${article['GA_CODEARTICLE'] ?? ''}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "€${article['GA_PVTTC'] ?? '0'}",
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: articles.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
