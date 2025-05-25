import 'package:flutter/material.dart';
import 'package:project/services/order_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final List<Map<String, dynamic>> lignes = [];
  String livraisonType = 'LOC'; // LOC = livraison, S001 = retrait
  String depot = '';
  int numero = DateTime.now().millisecondsSinceEpoch.remainder(100000); // simulate GP_NUMERO

  void addArticle() {
    setState(() {
      lignes.add({"article": "", "qte": 1});
    });
  }

  Future<void> submitOrder() async {
    try {
      final now = DateTime.now();

      final data = {
        "GP_NATUREPIECEG": "CMD",
        "GP_SOUCHE": "CMD001",
        "GP_NUMERO": numero,
        "GP_INDICEG": 0,
        "GP_DATECREATION": now.toIso8601String(),
        "GP_LIBRETIERS1": livraisonType,
        "GP_DEPOT": livraisonType.startsWith("S") ? depot : null,
        "lignes": lignes
            .map((l) => {
                  "GL_ARTICLE": l["article"],
                  "GL_QTEFACT": l["qte"],
                })
            .toList(),
      };

      await OrderService().createOrder(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Commande soumise avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Commande")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mode de livraison
            DropdownButtonFormField<String>(
              value: livraisonType,
              decoration: const InputDecoration(labelText: "Mode de livraison"),
              items: const [
                DropdownMenuItem(value: 'LOC', child: Text('Livraison')),
                DropdownMenuItem(value: 'S001', child: Text('Retrait S001')),
                DropdownMenuItem(value: 'S002', child: Text('Retrait S002')),
              ],
              onChanged: (val) => setState(() => livraisonType = val!),
            ),

            if (livraisonType.startsWith('S'))
              TextField(
                decoration: const InputDecoration(labelText: 'Dépôt'),
                onChanged: (val) => depot = val,
              ),

            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: lignes.length,
                itemBuilder: (context, index) {
                  final ligne = lignes[index];
                  return Card(
                    child: ListTile(
                      title: TextField(
                        decoration: const InputDecoration(labelText: 'Code Article'),
                        onChanged: (val) => ligne['article'] = val,
                      ),
                      subtitle: TextField(
                        decoration: const InputDecoration(labelText: 'Quantité'),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => ligne['qte'] = int.tryParse(val) ?? 1,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => lignes.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Ajouter Article"),
              onPressed: addArticle,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: submitOrder,
              child: const Text("Soumettre la commande"),
            )
          ],
        ),
      ),
    );
  }
}
