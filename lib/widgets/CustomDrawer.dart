// widgets/custom_drawer.dart
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String userRole;
  final Function(int) onItemSelected;
  final int selectedIndex;
  final List<String> titles;

  const CustomDrawer({
    super.key,
    required this.userRole,
    required this.onItemSelected,
    required this.selectedIndex,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      Icons.inventory,
      Icons.receipt_long,
      Icons.people,
      Icons.assignment_return,
      Icons.local_offer,
      Icons.bar_chart,
    ];

    return Drawer(
      child: ListView(
        padding: const EdgeInsets.only(top: 30),
        children: [
          ListTile(
            title: Text(
              userRole == 'admin' ? 'Admin Panel' : 'Mon Compte',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B5BDB)),
            ),
            leading: Icon(
              userRole == 'admin' ? Icons.admin_panel_settings : Icons.person,
              color: const Color(0xFF3B5BDB),
            ),
          ),
          const Divider(),
          for (int i = 0; i < titles.length; i++)
            ListTile(
              leading: Icon(icons[i % icons.length]),
              title: Text(titles[i]),
              selected: selectedIndex == i,
              selectedTileColor: Colors.grey[200],
              onTap: () => onItemSelected(i),
            ),
        ],
      ),
    );
  }
}
