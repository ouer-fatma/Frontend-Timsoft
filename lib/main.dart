import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:project/screens/User/Home_screen.dart';
import 'package:project/screens/User/chat_screen.dart';
import 'package:project/screens/admin/admin_dashboard_screen.dart';
import 'package:project/screens/admin/admin_home_page.dart';
import 'package:project/screens/auth/reset_password_page.dart';
import 'package:project/screens/magasinier/magasinier_home_screen.dart';
import 'package:project/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:project/screens/User/ValidationCommandeScreen.dart';
import 'package:project/screens/User/client_promotions_screen.dart';
import 'package:project/screens/User/familles_screen.dart';
import 'package:project/services/home_service.dart';
import 'package:project/services/panier_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:project/config.dart';
import 'package:project/screens/User/article_detail_screen.dart';
import 'package:project/screens/admin/admin_home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:project/screens/auth/splash_screen.dart';
import 'package:project/services/storage_service.dart';
import 'package:project/widgets/login_side_panel.dart';
import 'package:project/widgets/register_side_panel.dart';
import 'package:project/screens/admin/create_magasinier_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lottie/lottie.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔕 [BG] Message reçu : ${message.messageId}');
}

Future<void> sendTokenToBackend(String token) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3000/notifications/subscribe'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );
    print('📬 Token envoyé au backend: ${response.statusCode}');
  } catch (e) {
    print('❌ Erreur lors de l’envoi du token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final Uri uri = Uri.base;
  final String? resetToken = uri.queryParameters['token'];

  // 🔐 Canal Android (mobile uniquement)
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel_id',
    'Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ❗Ne pas bloquer l’UI ici. On fait les permissions/token après dans le splash.

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel_id',
            'Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

      NotificationService.notify({
        'title': notification.title,
        'message': notification.body,
        'date': DateTime.now().toIso8601String(),
      });
    }
  });

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F5F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: resetToken != null
          ? ResetPasswordPage(token: resetToken) // 👈 Si token dans l’URL
          : const SplashScreen(), // 👈 Sinon workflow habituel
    ),
  );
}

class AuthRedirector extends StatelessWidget {
  const AuthRedirector({super.key});

  Future<Widget> _decideStartScreen() async {
    final token = await StorageService.getToken();

    if (token == null || JwtDecoder.isExpired(token)) {
      return const WelcomeScreen();
    }

    final decoded = JwtDecoder.decode(token);
    final role = decoded['role'] ?? 'client';
    final email = decoded['email'] ?? '';
    final nom = decoded['nom'] ?? decoded['T_LIBELLE'] ?? email;

    if (role == 'admin') {
      return const AdminDashboardScreen();
    } else if (role == 'personnel_magasin') {
      return const MagasinierHomeScreen();
    } else {
      return HomeScreen(userNom: nom, userEmail: email, userRole: role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decideStartScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.data,
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timsoft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F5F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<dynamic> articles = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final List<String> banners = [
    'assets/banners/banner1.png',
    'assets/banners/banner2.png',
    'assets/banners/banner3.png',
  ];
  List<dynamic> topTrends = [];

  Future<void> fetchTopTrends() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/articles/specific'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Grouper par GA_CODEARTICLE1
        final Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var article in data) {
          final codeParent = article['GA_CODEARTICLE'];
          print("Code parent = $codeParent");

          if (codeParent == null) continue;

          grouped.putIfAbsent(codeParent, () => []);
          grouped[codeParent]!.add(article);
        }

        // Pour chaque groupe, prendre le premier article comme affichage
        final uniqueArticles = grouped.entries
            .map((entry) {
              final articleVariants = entry.value;
              final baseArticle = articleVariants.first;

              // Convertir image base64 depuis IMAGE.data
              String? base64Image;
              if (baseArticle['IMAGE'] != null &&
                  baseArticle['IMAGE']['data'] != null &&
                  baseArticle['IMAGE']['data'] is List) {
                final imageData = baseArticle['IMAGE']['data'];
                final bytes = Uint8List.fromList(imageData.cast<int>());
                base64Image = base64Encode(bytes);
              }

              return {
                "title": baseArticle['GA_LIBELLE'] ?? 'Sans titre',
                "label": "#TOP",
                "image": base64Image != null
                    ? 'data:image/jpeg;base64,$base64Image'
                    : null,
                "GA_CODEARTICLE": baseArticle['GA_CODEARTICLE'],
                "GA_CODEARTICLE1": baseArticle['GA_CODEARTICLE1'],
                "GA_PVTTC": baseArticle['GA_PVTTC'],
                "variantes": articleVariants, // 🧠 Passer les variantes ici
              };
            })
            .where((a) => a['image'] != null)
            .toList();

        setState(() {
          topTrends = uniqueArticles;
          print("Longueur finale topTrends = ${topTrends.length}");
        });
      } else {
        print('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur de récupération des tendances: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // ✅ Clean up
    super.dispose();
  }

  final List<String> placeholderImages = [
    'assets/articles/Blouse.jpg',
    'assets/articles/chemise.jpg',
    'assets/articles/Pull.jpg',
    'assets/articles/Sweat.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _redirectIfAuthenticated();
    Future.delayed(const Duration(milliseconds: 500), _showWelcomePopup);
    fetchArticles();
    fetchTopTrends();
  }

  Future<void> _redirectIfAuthenticated() async {
    final token = await StorageService.getToken();
    if (token != null && mounted) {}
  }

  Future<void> fetchArticles() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/articles');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          articles = data;
          isLoading = false;
        });
      } else {
        print("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur fetch: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _searchArticlesPublic(String query) async {
    setState(() => isLoading = true);
    try {
      final results = await ArticleService().publicSearchArticles(query);
      setState(() {
        articles = results;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur recherche publique: $e");
      setState(() => isLoading = false);
    }
  }

  void _showWelcomePopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/gift.json', height: 120),
            const Text("Offre spéciale rien que pour vous !",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("-60% pour toute commande",
                style: TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Collecter Tout"),
            ),
          ],
        ),
      ),
    );
  }

  void openFamillesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Catégories",
      barrierColor: Colors.black.withOpacity(0.3), // optional overlay
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0), // Slide from left
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.65,
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        "CATEGORIES",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: FamillesScreen()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openLoginModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Login",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Opacity(
                opacity: 0.4,
                child: Container(color: Colors.black),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(animation),
                child: const LoginSidePanel(),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSearchOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Recherche",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
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
                      // Fermer
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

                      // Champ de recherche
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
                            Navigator.of(context).pop(); // Ferme l'overlay
                            await _searchArticlesPublic(value);
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Suggestions
                      const Text(
                        "Dernières recherches :",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          _suggestionChip("pull"),
                          _suggestionChip("sneaker"),
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

  void _showCartSidePanel(BuildContext context) async {
    final userData = await StorageService.getUserData();
    final codeTiers = userData?['codeTiers'] ?? 'GUEST';

    final panierService = PanierService();
    List<dynamic> lignes = [];
    List<Map<String, dynamic>> depots = [];
    bool isRetrait = false;
    String? selectedDepot;
    bool isLoading = true;
    bool hasFetched = false; // ✅ important

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            // ✅ appelé une seule fois au premier build
            Future<void> fetchPanier() async {
              setState(() => isLoading = true);
              try {
                print("📦 fetchPanier() appelé pour $codeTiers");
                lignes = await panierService.getPanier(codeTiers: codeTiers);
                print("✅ ${lignes.length} ligne(s) reçue(s)");
              } catch (e) {
                print("❌ Erreur fetchPanier: $e");
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
              if (token == null || JwtDecoder.isExpired(token)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Authentification invalide.")));
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

            // ✅ lancer fetch une seule fois
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
                          onPressed: () async {
                            final token = await StorageService.getToken();
                            if (token == null) {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => const Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: LoginSidePanel(),
                                  ),
                                ),
                              );
                              return;
                            }

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

  Widget _buildTopIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.of(context).pop();
        _searchArticlesPublic(label);
      },
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Bienvenue sur TimRetail",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: () => setState(() {
              fetchArticles();
            }),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              backgroundColor: Colors.deepPurple,
            ),
            child: Row(
              children: const [
                Icon(Icons.shopping_bag_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text("Consulter les articles",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBannerSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height:
            180, // tu peux aussi enlever ça et laisser AspectRatio faire le taf
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: banners.map((img) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9, // ou 3 / 1 pour une bannière plus allongée
            child: Image.asset(
              img,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildTopTrends(BuildContext context) {
    final filteredTrends = topTrends;

    return Container(
      color: Colors.pink.shade50,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top tendances",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text("→ ${filteredTrends.length} article(s) chargés"),
          const SizedBox(height: 12),
          if (filteredTrends.isEmpty)
            const Text("Aucune tendance à afficher.")
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filteredTrends.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, index) {
                  final trend = filteredTrends[index];
                  final image = trend['image']?.toString() ?? '';
                  final title = trend['title']?.toString() ?? 'Article';
                  final label = trend['label']?.toString() ?? '';
                  final codeArticle1 = trend['GA_CODEARTICLE1'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      final variants = trend['variantes'] ?? [];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(
                            article: trend,
                            allVariants:
                                List<Map<String, dynamic>>.from(variants),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: image.startsWith('http') ||
                                    image.startsWith('data:image')
                                ? Image.network(image,
                                    height: 120,
                                    width: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/placeholder.jpg',
                                          height: 120,
                                          width: 150,
                                          fit: BoxFit.cover,
                                        ))
                                : Image.asset('assets/placeholder.jpg',
                                    height: 120, width: 150, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildArticleGrid() {
    // Replace with real article grid or restore old logic
    return Center(child: Text("Articles ici..."));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: buildBannerSlider()),
          SliverToBoxAdapter(child: buildTopTrends(context)),
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white.withOpacity(0.9),
            stretch: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed =
                    constraints.biggest.height <= kToolbarHeight + 10;
                return Container(
                  decoration: BoxDecoration(
                    color: isCollapsed
                        ? Colors.white.withOpacity(0.9)
                        : Colors.transparent,
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
                        // LEFT SIDE
                        IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Catégories',
                          onPressed: () {
                            Navigator.pop(
                                context); // closes any drawer/dialog if open
                            openFamillesDialog(); // opens your categories dialog
                          },
                        ),

                        const Spacer(),

                        // CENTER LOGO
                        Image.asset(
                          'assets/logo.png',
                          height: MediaQuery.of(context).size.width > 800
                              ? 120
                              : 100,
                        ),

                        const Spacer(),

                        // RIGHT SIDE
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.local_offer_outlined,
                                  color: Colors.red),
                              tooltip: 'Voir les promotions',
                              onPressed: () async {
                                try {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ClientPromotionsScreen()),
                                  );
                                } catch (e) {
                                  print("Erreur chargement promotions: $e");
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => showSearchOverlay(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              tooltip: 'Chatbot',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ChatScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.shopping_bag_outlined),
                              onPressed: () => _showCartSidePanel(context),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _openLoginModal(context),
                              child: const Text('Se connecter',
                                  style: TextStyle(color: Colors.black)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.zero,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: RegisterSidePanel(),
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.deepPurple),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                              child: const Text("S'inscrire",
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                                          a['GA_CODEARTICLE'] == codeArticle &&
                                          ((a['GA_CODEDIM1']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ??
                                                  false) ||
                                              (a['GA_CODEDIM2']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ??
                                                  false)))
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
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
                                                placeholderImages[index %
                                                    placeholderImages.length],
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              placeholderImages[index %
                                                  placeholderImages.length],
                                              fit: BoxFit.cover,
                                            ),
                                    ),

                                    // Infos produit (scrollables si besoin)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article['GA_LIBELLE'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Code: ${article['GA_CODEARTICLE'] ?? ''}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${article['GA_PVTTC'] ?? '0'} DT",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
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
