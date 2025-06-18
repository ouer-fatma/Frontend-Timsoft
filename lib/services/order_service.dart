import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderService {
  final String baseUrl = 'http://127.0.0.1:3000/orders';
  final String invoiceBaseUrl = 'http://127.0.0.1:3000/api/invoice';

  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes admin');
    }
  }

  Future<List<Map<String, dynamic>>> fetchClientOrders() async {
    final token = await StorageService.getToken();
    final payload = await StorageService.getUserData();
    final codeTiers = payload['codeTiers'];

    final response = await http.get(
      Uri.parse('$baseUrl/client/$codeTiers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes client');
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrdersForMagasinier() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception("Token introuvable");

    final response = await http.get(
      Uri.parse('http://localhost:3000/auth/magasin/bl-a-traiter'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération commandes magasinier');
    }
  }

  Future<List<Map<String, dynamic>>> fetchReturns() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse('http://127.0.0.1:3000/returns'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Erreur chargement retours: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getOrderDetails({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final token = await StorageService.getToken();
    final url = '$baseUrl/details/$nature/$souche/$numero/$indice';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération détails commande');
    }
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur création commande');
    }
  }

  Future<void> updateOrder({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
    required Map<String, dynamic> updateData,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour commande');
    }
  }

  Future<void> updateOrderStatus({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
    required String status,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({ 'status': status }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour du statut');
    }
  }

  Future<void> deleteOrder({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final token = await StorageService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$nature/$souche/$numero/$indice'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression commande');
    }
  }

  

  String getExistingBLDownloadUrl({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) {
    return '$invoiceBaseUrl/bl/existing/$nature/$souche/$numero/$indice';
  }

  String getBLDownloadUrl({
  required String nature,
  required String souche,
  required int numero,
  required String indice,
   String? depot,
  bool existing = false,
}) {
  final base = existing
      ? '$invoiceBaseUrl/bl/existing/$nature/$souche/$numero/$indice'
      : '$invoiceBaseUrl/bl/download/$nature/$souche/$numero/$indice';
return (depot != null && depot.isNotEmpty) ? '$base?depot=$depot' : base;
}


  Future<void> openPdfUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Impossible d’ouvrir le PDF.");
    }
  }

  Future<List<Map<String, dynamic>>> getDepotsDisponibles({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
  }) async {
    final token = await StorageService.getToken();
    final url = '$baseUrl/commandes/$souche/$numero/depots-disponibles?indice=$indice&nature=$nature';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Erreur récupération dépôts disponibles');
    }
  }

  Future<void> generateAndDownloadBLWithMultipleDepots({
    required String nature,
    required String souche,
    required int numero,
    required String indice,
    required Map<String, String> depotsParArticle,
  }) async {
    final jsonMap = jsonEncode(depotsParArticle);
    final query = Uri.encodeQueryComponent(jsonMap);

    final url = '$invoiceBaseUrl/bl/download/$nature/$souche/$numero/$indice?depotsParArticle=$query';

    await openPdfUrl(url);
  }

 Future<List<Map<String, dynamic>>> fetchReservationsPourMagasinier() async {
  final token = await StorageService.getToken();

  final response = await http.get(
    Uri.parse('http://localhost:3000/orders/magasinier/reservations'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Erreur récupération des réservations.');
  }
}
Future<List<Map<String, dynamic>>> getDepotsDisponiblesPourArticleCommande({
  required String souche,
  required int numero,
  required String articleCode,
}) async {
  final url = 'http://localhost:3000/orders/commandes/$souche/$numero/depots-disponibles/$articleCode';
  final response = await http.get(
    Uri.parse(url),
    headers: await headersWithToken(),
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Erreur récupération des dépôts pour cet article');
  }
}


Future<Map<String, String>> headersWithToken() async {
  final token = await StorageService.getToken();
  if (token == null) throw Exception("Token introuvable");

  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

Future<void> transferStock({
  required String codeArticle,
  required double quantite, // <-- ici
  required String depotSource,
  required String depotDestination,
  String? reference,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/api/stock-transfer/transfer'),
    headers: await headersWithToken(),
    body: jsonEncode({
      'codeArticle': codeArticle,
      'quantite': quantite,
      'depotSource': depotSource,
      'depotDestination': depotDestination,
      'reference': reference ?? '',
    }),
  );

  if (response.statusCode != 200) {
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Erreur transfert');
  }
}
Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
 Future<List<Map<String, dynamic>>> fetchRecentTransfers(String depot) async {
    final token = await StorageService.getToken(); // si tu as un token auth
    final uri = Uri.parse("http://localhost:3000/api/stock-transfer/stock-transfer/recents?depot=$depot");

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // si tu utilises un token
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erreur récupération des transferts : ${response.statusCode}");
    }
  }
}