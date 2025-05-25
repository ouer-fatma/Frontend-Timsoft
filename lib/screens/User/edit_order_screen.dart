// 📄 edit_order_screen.dart
import 'package:flutter/material.dart';

class EditOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late List<Map<String, dynamic>> lignes;

  @override
  void initState() {
    super.initState();
    lignes = List<Map<String, dynamic>>.from(widget.order['lignes'] ?? []);
  }

  void updateOrder() {
    // Appeler l'API de mise à jour ici
    print("Commande mise à jour: $lignes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier Commande")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: lignes.length,
              itemBuilder: (context, index) {
                final ligne = lignes[index];
                return ListTile(
                  title: TextFormField(
                    initialValue: ligne['GL_ARTICLE'],
                    onChanged: (val) => ligne['GL_ARTICLE'] = val,
                  ),
                  subtitle: TextFormField(
                    initialValue: ligne['GL_QTEFACT'].toString(),
                    onChanged: (val) => ligne['GL_QTEFACT'] = int.tryParse(val) ?? 1,
                    keyboardType: TextInputType.number,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => lignes.removeAt(index)),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: updateOrder,
            child: const Text("Mettre à jour"),
          )
        ],
      ),
    );
  }
}
