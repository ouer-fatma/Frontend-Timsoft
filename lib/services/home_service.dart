import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:project/config.dart';
import 'package:project/services/storage_service.dart';
import 'dart:io';

class ArticleService {
  String get _baseUrl => '${AppConfig.baseUrl}/articles';

  Future<List<Map<String, dynamic>>> fetchArticles() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch articles: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/search/$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> publicSearchArticles(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search/$query'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur (public search): ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> publicFetchArticles() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<void> createArticle({
    required String code,
    required String libelle,
    required double pvht,
    required double pvttc,
    PlatformFile? image,
  }) async {
    final token = await StorageService.getToken();
    final uri = Uri.parse(_baseUrl);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['GA_ARTICLE'] = code
      ..fields['GA_CODEARTICLE'] = code
      ..fields['GA_CODEBARRE'] = ''
      ..fields['GA_LIBELLE'] = libelle
      ..fields['GA_PVHT'] = pvht.toString()
      ..fields['GA_PVTTC'] = pvttc.toString()
      ..fields['GA_TENUESTOCK'] = 'O';

    if (image != null) {
      if (kIsWeb) {
        if (image.bytes == null) throw Exception("Image invalide.");
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          image.bytes!,
          filename: image.name,
        ));
      } else {
        if (image.path == null) throw Exception("Chemin d'image invalide.");
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path!,
        ));
      }
    }

    final response = await request.send();

    if (response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception("Erreur création: $respStr");
    }
  }

  Future<void> updateArticle({
    required String id,
    required String libelle,
    required double pvht,
    required double pvttc,
    required String tenueStock,
    PlatformFile? image,
  }) async {
    final token = await StorageService.getToken();
    final uri = Uri.parse('$_baseUrl/$id');

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['GA_LIBELLE'] = libelle
      ..fields['GA_PVHT'] = pvht.toString()
      ..fields['GA_PVTTC'] = pvttc.toString()
      ..fields['GA_TENUESTOCK'] = tenueStock;

    if (image != null) {
      if (kIsWeb) {
        if (image.bytes == null) throw Exception("Image invalide.");
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          image.bytes!,
          filename: image.name,
        ));
      } else {
        if (image.path == null) throw Exception("Chemin d'image invalide.");
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path!,
        ));
      }
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception("Erreur mise à jour: $respStr");
    }
  }

  Future<void> deleteArticle(String id) async {
    final token = await StorageService.getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur suppression: ${response.body}");
    }
  }
}
