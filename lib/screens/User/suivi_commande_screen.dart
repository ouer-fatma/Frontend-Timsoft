import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:project/services/storage_service.dart';
import 'package:universal_html/html.dart' as html;

class SuiviCommandeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> articles;
  final double total;
  final String livraison;
  final String numeroCommande;
  final String nature;
  final String souche;
  final int numero;
  final int indice;

  const SuiviCommandeScreen({
    super.key,
    required this.articles,
    required this.total,
    required this.livraison,
    required this.numeroCommande,
    required this.nature,
    required this.souche,
    required this.numero,
    required this.indice,
  });

  Future<void> generateAndPrintPDF({
    required List<Map<String, dynamic>> articles,
    required double total,
    required String livraison,
    required String numeroCommande,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("Facture - Commande n° $numeroCommande",
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text("Mode de livraison : $livraison"),
          pw.SizedBox(height: 12),
          pw.Text("Détails des articles :"),
          pw.SizedBox(height: 8),
          ...articles.map((item) {
            final libelle = item['GA_LIBELLE'] ?? 'Article';
            final quantite = item['GL_QTEFACT'] ?? '-';
            final taille = item['dim1Libelle'] ?? '-';
            final couleur = item['dim2Libelle'] ?? '-';
            final totalLigne = (item['TotalLigne'] ?? 0.0).toStringAsFixed(2);

            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(libelle)),
                  pw.Text("Qté: $quantite"),
                  pw.Text("Taille: $taille"),
                  pw.Text("Couleur: $couleur"),
                  pw.Text("$totalLigne DT"),
                ],
              ),
            );
          }),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text("Total TTC : ",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text("${total.toStringAsFixed(2)} DT",
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> downloadInvoicePDF({
    required String nature,
    required String souche,
    required int numero,
    required int indice,
    required String token,
  }) async {
    final dio = Dio();
    final url =
        "http://localhost:3000/api/invoice/download/$nature/$souche/$numero/$indice";

    try {
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final pdfBytes = response.data;

      if (kIsWeb) {
        // ✅ Web download via anchor tag
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "facture_$numero.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // ✅ Mobile/Desktop
        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/facture_${numero}_$indice.pdf";
        final file = io.File(filePath);
        await file.writeAsBytes(Uint8List.fromList(pdfBytes));

        await OpenFile.open(filePath);
      }
    } catch (e) {
      print("❌ Erreur téléchargement PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suivi de commande")),
      backgroundColor: const Color(0xFFF7F5F2),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Commande n° $numeroCommande",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Livraison : $livraison"),
            const Divider(height: 32),
            const Text("Articles :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: articles.isEmpty
                  ? const Text("Aucun article.")
                  : ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (_, index) {
                        final item = articles[index];
                        final libelle = item['GA_LIBELLE'] ?? 'Article';
                        final quantite = item['GL_QTEFACT'] ?? '-';
                        final taille = item['dim1Libelle'] ?? '-';
                        final couleur = item['dim2Libelle'] ?? '-';
                        final totalLigne = item['TotalLigne'] ?? 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(libelle),
                              subtitle: Text(
                                  "Qté: $quantite • Taille: $taille • Couleur: $couleur"),
                              trailing: Text(
                                "${totalLigne.toStringAsFixed(2)} DT",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total TTC :",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("${total.toStringAsFixed(2)} DT",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("Retour à l'accueil"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5BDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final token = await StorageService.getToken();
                      if (token == null) return;

                      await downloadInvoicePDF(
                        nature: nature,
                        souche: souche,
                        numero: numero,
                        indice: indice,
                        token: token,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Télécharger la facture"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
