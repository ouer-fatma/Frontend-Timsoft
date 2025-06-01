import 'package:flutter/material.dart';
import 'package:project/screens/User/article_detail_screen.dart';
import 'package:project/screens/User/panier_screen.dart';
import 'package:project/screens/User/user_profile_screen.dart';
import 'package:project/screens/User/familles_screen.dart';
import 'package:project/screens/User/user_orders_screen.dart';
import 'package:project/services/Home_service.dart';
import 'dart:convert';
import 'package:project/screens/auth/Login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:project/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
  String? userRole;
  String? codeTiers;

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> articles = [];
  bool isLoading = true;

  final List<String> placeholderImages = [
    'assets/articles/Blouse.jpg',
    'assets/articles/chemise.jpg',
    'assets/articles/Pull.jpg',
    'assets/articles/Sweat.jpg',
  ];

  @override
  void initState() {
    super.initState();
    userName = widget.userNom;
    userEmail = widget.userEmail;
    userRole = widget.userRole;
    fetchArticles();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final token = await StorageService.getToken();
    if (token == null) return;
    try {
      final decoded = JwtDecoder.decode(token);
      if (!mounted) return;
      setState(() {
        userName = decoded['nom'] ?? decoded['email'] ?? 'Utilisateur';
        userEmail = decoded['email'];
        userRole = decoded['role'];
        codeTiers = decoded['codeTiers'];
      });
    } catch (e) {
      print("Erreur JWT: $e");
    }
  }

  Future<void> fetchArticles() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/articles'));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur fetch: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> searchArticles(String query) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/articles/search/$query'));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur recherche: $e");
    }
    setState(() => isLoading = false);
  }

  void openFamillesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.only(left: 100),
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width * 0.65,
          child: Material(
            borderRadius: BorderRadius.circular(12),
            child: FamillesScreen(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: [
            const ListTile(
              title: Text(
                "Menu Client",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B5BDB)),
              ),
              leading: Icon(Icons.menu, color: Color(0xFF3B5BDB)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Profil"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userName: userName ?? '',
                      userEmail: userEmail ?? '',
                      userRole: userRole ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Accueil"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Catégories"),
              onTap: () {
                Navigator.pop(context);
                openFamillesDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Mes Commandes"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserOrdersScreen(codeTiers: codeTiers ?? ''),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Paramètres"),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white.withOpacity(0.9),
            stretch: true,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final isCollapsed = constraints.biggest.height <= kToolbarHeight + 10;
                return Container(
                  decoration: BoxDecoration(
                    color: isCollapsed ? Colors.white.withOpacity(0.9) : Colors.transparent,
                    border: isCollapsed ? const Border(bottom: BorderSide(color: Colors.black12)) : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      bottom: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Image.asset('assets/logo.png', height: isCollapsed ? 40 : 80),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart),
                              onPressed: () async {
                                if (codeTiers != null) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(child: CircularProgressIndicator()),
                                  );
                                  await Future.delayed(const Duration(milliseconds: 150));
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PanierScreen(codeTiers: codeTiers!),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("CodeTiers non disponible.")),
                                  );
                                }
                              },
                            ),
                            TextButton(
                              onPressed: () async {
                                await StorageService.clearToken();
                                if (!mounted) return;
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              },
                              child: const Text('Se déconnecter', style: TextStyle(color: Colors.black)),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Center(
                    child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      totalRepeatCount: 1,
                      animatedTexts: [
                        TyperAnimatedText(
                          'Votre partenaire pour une expérience de mode réinventée',
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF495057)),
                          speed: const Duration(milliseconds: 50),
                        ),
                      ],
                    ),
                  ),
                  if (userName != null || userEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Bienvenue, ${userName ?? ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => value.isEmpty ? fetchArticles() : searchArticles(value),
                decoration: InputDecoration(
                  hintText: "Rechercher un article...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = articles[index];
                      final image = placeholderImages[index % placeholderImages.length];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(article: article),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  article['GA_IMAGE_URL'] ?? '',
                                  height: 140,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    image,
                                    height: 140,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article['GA_LIBELLE'] ?? 'Sans libellé',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Code: ${article['GA_CODEARTICLE'] ?? ''}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "€${article['GA_PVTTC'] ?? '0'}",
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
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
        ],
      ),
    );
  }
}
