import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:project/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:project/screens/User/ValidationCommandeScreen.dart';
import 'package:project/screens/User/client_promotions_screen.dart';
import 'package:project/screens/User/familles_screen.dart';
import 'package:project/services/home_service.dart';
import 'package:project/services/panier_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔕 [BG] Message reçu : ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ ESSENTIEL pour Web
  );

  // 🔐 Configuration du canal pour Android
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel_id', // ⚠️ Doit correspondre à l'ID utilisé plus bas
    'Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ Permission (mobile + web)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Web seulement : enregistrer le Service Worker + obtenir le token avec VAPID key
  if (kIsWeb) {
    await Future.delayed(
        const Duration(seconds: 2)); // ✅ Laisse le SW se charger
    try {
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey:
            'BIqXdbvEywygX6IVNP8X1d6tmm0B6pEF2QoeWC5Gw1Yc-H20BX1c5UvsRgj_ePC1tF1vHfGW4AhUduIhq2ktq0g',
      );
      print('🌐 FCM Web Token: $token');
    } catch (e) {
      print('❌ Erreur récupération token Web: $e');
    }
  }

// ✅ Activer la gestion des messages FCM en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// ✅ Réception des messages FCM en premier plan
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      // 🔔 Afficher une notification locale
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

      // 📣 Propager la notif à l'écran client s'il est actif
      NotificationService.notify({
        'title': notification.title,
        'message': notification.body,
        'date': DateTime.now().toIso8601String(),
      });
    }
  });

  // ✅ S'abonner au topic "promotions"
  if (!kIsWeb) {
    await FirebaseMessaging.instance.subscribeToTopic('promotions');
  }

  runApp(const MyApp());
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
    fetchArticles();
  }

  Future<void> _redirectIfAuthenticated() async {
    final token = await StorageService.getToken();
    if (token != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }
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
                        "FEMME",
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
    print("🛒 Cart icon tapped!");
    final userData = await StorageService.getUserData();
    final codeTiers = userData?['codeTiers'] ?? 'GUEST';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: PanierService().getPanier(codeTiers: codeTiers),
          builder: (context, snapshot) {
            final panier = snapshot.data ?? [];

            double total = panier.fold(
              0.0,
              (sum, item) => sum + (item['TotalLigne'] ?? 0.0),
            );

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
                        const Text(
                          "Mon panier",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : snapshot.hasError
                                  ? Center(
                                      child: Text("Erreur: ${snapshot.error}"),
                                    )
                                  : panier.isEmpty
                                      ? const Center(
                                          child: Text("Votre panier est vide."),
                                        )
                                      : ListView.builder(
                                          itemCount: panier.length,
                                          itemBuilder: (_, index) {
                                            final item = panier[index];

                                            final libelle =
                                                item['GA_LIBELLE'] ?? 'Article';
                                            final quantite =
                                                item['GL_QTEFACT'] ?? '-';
                                            final taille =
                                                item['dim1Libelle'] ?? '-';
                                            final couleur =
                                                item['dim2Libelle'] ?? '-';
                                            final totalLigne =
                                                item['TotalLigne'] ?? 0.0;

                                            return ListTile(
                                              leading: const Icon(
                                                  Icons.shopping_bag),
                                              title: Text(libelle),
                                              subtitle: Text(
                                                  "Qté: $quantite - Taille: $taille - Couleur: $couleur"),
                                              trailing: Text(
                                                "€${totalLigne.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            );
                                          },
                                        ),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.hasData && panier.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    // ❌ Pas connecté → Rediriger vers login
                                    Navigator.of(context)
                                        .pop(); // Ferme le panel d'abord
                                    showDialog(
                                      context: context,
                                      builder: (_) => const Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child:
                                              LoginSidePanel(), // ou autre widget de login
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ✅ Connecté → Accès autorisé
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ValidationCommandeScreen()),
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {},
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
                                builder: (_) =>
                                    ArticleDetailScreen(article: article),
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
                                  child: Image.network(
                                    article['GA_IMAGE_URL'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Image.asset(image, fit: BoxFit.cover),
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
                                        "${article['GA_PVTTC'] ?? '0'} DT",
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
