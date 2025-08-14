import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PanierLocalService {
  static const _key = 'panier_guest';

  static Future<void> addArticle(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_key) ?? [];
    current.add(jsonEncode(article));
    await prefs.setStringList(_key, current);
  }

  static Future<List<Map<String, dynamic>>> getArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> removeArticle(String codeArticle, String codesdim) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final updated = list.where((e) {
      final item = jsonDecode(e);
      return !(item['codeArticle'] == codeArticle && item['codesdim'] == codesdim);
    }).toList();

    await prefs.setStringList(_key, updated);
  }

  static Future<void> clearPanier() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
