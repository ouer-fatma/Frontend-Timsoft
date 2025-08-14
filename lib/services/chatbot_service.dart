import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
// ⚠️ Si tu cibles le Web, préfère des imports conditionnels pour éviter dart:io.
// Pour mobile/desktop uniquement, ceci marche :
import 'dart:io' show Platform;

class ChatReply {
  final String type; // 'smalltalk' | 'faq' | 'products' | 'error'
  final String? text;   // message pour smalltalk/faq/erreur
  final String? topic;  // ex: 'livraison'
  final List<Map<String, dynamic>> items;

  ChatReply({
    required this.type,
    this.text,
    this.topic,
    this.items = const [],
  });

  factory ChatReply.fromJson(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final items = (decoded['items'] is List)
          ? (decoded['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      return ChatReply(
        type: (decoded['type'] ?? 'products').toString(),
        text: decoded['text']?.toString(),
        topic: decoded['topic']?.toString(),
        items: items,
      );
    }
    if (decoded is List) {
      // legacy /match-mot renvoie une liste brute d’articles
      final items = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      return ChatReply(type: 'products', items: items);
    }
    return ChatReply(type: 'error', text: 'Réponse serveur inattendue');
  }
}

class ChatbotService {
  ChatbotService({String? base}) : _base = base ?? _defaultBase();

  static String _defaultBase() {
    if (kIsWeb) {
      final uri = Uri.base; // ex: http://localhost:59700/#/
      final host = uri.host.isEmpty ? '127.0.0.1' : uri.host;
      final scheme = (uri.scheme == 'https') ? 'https' : 'http';
      return '$scheme://$host:5001';
    } else {
      if (Platform.isAndroid) return 'http://10.0.2.2:5001';
      return 'http://127.0.0.1:5001';
    }
  }

  final String _base;

  /// ✅ Nouveau: endpoint conversation /chat (fallback vers /match-mot)
  Future<ChatReply> chat(String message,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final url = Uri.parse('$_base/chat');

    http.Response resp;
    try {
      resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            // envoie "message"; si ton backend accepte aussi "mot", c'est OK
            body: jsonEncode({'message': message}),
          )
          .timeout(timeout);
    } catch (e) {
      return ChatReply(type: 'error', text: 'Connexion impossible: $e');
    }

    if (resp.statusCode == 404) {
      // Ancien backend sans /chat -> fallback
      final legacy = await matchMot(message, timeout: timeout);
      return ChatReply(type: 'products', items: legacy);
    }

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      return ChatReply.fromJson(decoded);
    }

    return ChatReply(
      type: 'error',
      text:
          'Erreur ${resp.statusCode}: ${resp.body.isEmpty ? "Aucun détail" : resp.body}',
    );
  }

  /// Compat: appelle directement /match-mot et renvoie une liste d’articles
  Future<List<Map<String, dynamic>>> matchMot(String mot,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final url = Uri.parse('$_base/match-mot'); // 🔧 corrigé (avant: /chat)

    final resp = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'mot': mot}),
        )
        .timeout(timeout);

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is List) {
        return body
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(growable: false);
      }
      // Si jamais le backend renvoie un objet, on l'encapsule
      return [Map<String, dynamic>.from(body as Map)];
    }

    throw Exception(
        'RAG error ${resp.statusCode}: ${resp.body.isEmpty ? "No body" : resp.body}');
  }
}
