import 'package:flutter/material.dart';
import 'package:project/screens/admin/users_screen.dart';
import 'admin_home_screen.dart';
import 'admin_home_page.dart';
import 'package:project/screens/admin/orders_screen.dart';

// Placeholder widgets for other sections
Widget _buildPlaceholder(String title) => Center(
      child: Text(title, style: const TextStyle(fontSize: 24)),
    );

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int selectedIndex = 0;

  final List<String> _titles = [
    "Accueil",
    "Articles",
    "Commandes",
    "Utilisateurs",
    "Retours",
    "Promotions",
    "Statistiques",
  ];

  final List<Widget> _screens = [
    const AdminHomePage(), // Accueil
    const AdminHomeScreen(), // Articles
    const OrdersScreen(), // replaces _buildPlaceholder("Commandes")

    const UsersScreen(),
    _buildPlaceholder("Retours"),
    _buildPlaceholder("Promotions"),
    _buildPlaceholder("Statistiques"), // ✅ This line was missing!
  ];

  void _onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
      Navigator.pop(context); // close the drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - ${_titles[selectedIndex]}"),
        backgroundColor: const Color(0xFF3B5BDB),
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: [
            const ListTile(
              title: Text(
                "Admin Panel",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B5BDB)),
              ),
              leading:
                  Icon(Icons.admin_panel_settings, color: Color(0xFF3B5BDB)),
            ),
            const Divider(),
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon([
                  Icons.home,
                  Icons.inventory,
                  Icons.receipt_long,
                  Icons.people,
                  Icons.assignment_return,
                  Icons.local_offer,
                  Icons.bar_chart,
                ][i]),
                title: Text(_titles[i]),
                selected: selectedIndex == i,
                selectedTileColor: Colors.grey[200],
                onTap: () => _onItemSelected(i),
              ),
          ],
        ),
      ),
      body: _screens[selectedIndex],
    );
  }
}
