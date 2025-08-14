import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/models/RemiseType.dart';

class Promotion {
  final String gtrTypeRemise;
  final String libelle;
  final String abrege;
  final String imprimable;

  Promotion({
    required this.gtrTypeRemise,
    required this.libelle,
    required this.abrege,
    required this.imprimable,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      gtrTypeRemise: json['GTR_TYPEREMISE'],
      libelle: json['GTR_LIBELLE'],
      abrege: json['GTR_ABREGE'],
      imprimable: json['GTR_IMPRIMABLE'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'GTR_TYPEREMISE': gtrTypeRemise,
      'GTR_LIBELLE': libelle,
      'GTR_ABREGE': abrege,
      'GTR_IMPRIMABLE': imprimable,
    };
  }
}

class PromotionService {
  final String baseUrl = "http://localhost:3000/api/promotions";

  // ---------------------- PROMOTIONS CRUD BASE ----------------------
  Future<List<Promotion>> fetchPromotions() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des promotions");
    }
  }

  Future<void> addPromotion(Promotion promo) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promo.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception("Erreur lors de l'ajout de la promotion");
    }
  }

  Future<void> updatePromotion(String id, Promotion promo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promo.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Erreur lors de la mise à jour");
    }
  }

  Future<void> deletePromotion(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression");
    }
  }

  // ---------------------- ARTICLE PROMO ----------------------

  Future<void> setPromoToArticle(String codeArticle, String typeRemise) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promo-article'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeArticle': codeArticle,
        'typeRemise': typeRemise,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur ajout promo à article");
    }
  }

  Future<void> updatePromoForArticle(
      String codeArticle, String typeRemise) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promo-article/$codeArticle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codeArticle': codeArticle,
        'typeRemise': typeRemise,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur mise à jour promo article");
    }
  }

  Future<void> deletePromoForArticle(String codeArticle) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/promo-article/$codeArticle'));
    if (response.statusCode != 200) {
      throw Exception("Erreur suppression promo article");
    }
  }

  Future<List<Promotion>> getPromosByArticle(String codeArticle) async {
    final response =
        await http.get(Uri.parse('$baseUrl/by-article/$codeArticle'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception("Erreur récupération promo par article");
    }
  }

  // ---------------------- CATEGORY PROMO ----------------------

  Future<void> setPromoToCategory(String category, String typeRemise) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promo-category'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'typeRemise': typeRemise,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur ajout promo catégorie");
    }
  }

  Future<void> updatePromoForCategory(
      String category, String typeRemise) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promo-category/$category'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'typeRemise': typeRemise,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur mise à jour promo catégorie");
    }
  }

  Future<void> deletePromoForCategory(String category) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/promo-category/$category'));
    if (response.statusCode != 200) {
      throw Exception("Erreur suppression promo catégorie");
    }
  }

  Future<List<Promotion>> getPromosByCategory(String category) async {
    final response =
        await http.get(Uri.parse('$baseUrl/by-category/$category'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Promotion.fromJson(e)).toList();
    } else {
      throw Exception("Erreur récupération promo par catégorie");
    }
  }

  // ---------------------- EXTRA: CATEGORIES & REMISE TYPES ----------------------

  Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      // filtre les null ou vides
      return data
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } else {
      throw Exception("Erreur lors de la récupération des catégories");
    }
  }

  Future<List<RemiseType>> fetchRemiseTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/remise-types'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RemiseType.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des types de remise");
    }
  }

  Future<Map<String, List<Promotion>>> getAllCategoryPromos() async {
    final List<String> categories = await fetchCategories();
    Map<String, List<Promotion>> promosByCat = {};

    for (final cat in categories) {
      if (cat.trim().isEmpty) continue;

      final promos = await getPromosByCategory(cat);
      if (promos.isNotEmpty) {
        promosByCat[cat] = promos;
      }
    }

    return promosByCat;
  }
}
