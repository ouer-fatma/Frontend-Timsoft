import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MagasinierReturnsScreen extends StatefulWidget {
  const MagasinierReturnsScreen({super.key});

  @override
  State<MagasinierReturnsScreen> createState() => _MagasinierReturnsScreenState();
}

class _MagasinierReturnsScreenState extends State<MagasinierReturnsScreen> {
  List<Map<String, dynamic>> retours = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllRetours();
  }

  Future<void> fetchAllRetours() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/retours'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          retours = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception("Erreur serveur");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📦 Retours Clients")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : retours.isEmpty
              ? const Center(child: Text("Aucun retour enregistré."))
              : ListView.builder(
                  itemCount: retours.length,
                  itemBuilder: (context, index) {
                    final retour = retours[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text("Retour N°: ${retour['GP_NUMERO']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client: ${retour['GP_TIERS']}"),
                            Text("Date: ${retour['GP_DATEPIECE']}"),
                            Text("Article: ${retour['GL_ARTICLE']}"),
                            Text("Quantité: ${retour['GL_QTEFACT']}"),
                            Text("Dépôt: ${retour['GL_DEPOT']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
