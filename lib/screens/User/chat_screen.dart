import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/screens/User/article_detail_screen.dart';
import 'package:project/services/chatbot_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 👉 Utilise l’endpoint /chat (fallback auto vers /match-mot côté service)
      final reply = await _chatbotService.chat(userMessage);

      if (reply.type == 'error') {
        _messages
            .add({'sender': 'bot', 'text': reply.text ?? 'Erreur inconnue.'});
      } else if (reply.type == 'smalltalk' || reply.type == 'faq') {
        _messages.add({'sender': 'bot', 'text': reply.text ?? ''});
      } else if (reply.type == 'products') {
        final items = reply.items;
        if (items.isEmpty) {
          // Le backend peut fournir un texte explicatif
          _messages.add(
              {'sender': 'bot', 'text': reply.text ?? 'Aucun article trouvé.'});
        } else {
          for (final item in items) {
            final code = (item['GA_CODEARTICLE'] ?? '').toString();
            final libelle = (item['GA_LIBELLE'] ?? '').toString();
            final prix = (item['GA_PVTTC'] ?? '').toString();
            final image = (item['IMAGE'] ?? '') as String? ?? '';

            _messages.add({
              'sender': 'bot',
              'text': 'Article: $libelle - ${prix}€',
            });

            final variantesList = (item['variantes'] is List)
                ? List<Map<String, dynamic>>.from(item['variantes'])
                : <Map<String, dynamic>>[];

            final articlePayload = jsonEncode({
              'GA_CODEARTICLE': code,
              'GA_LIBELLE': libelle,
              'GA_PVTTC': item['GA_PVTTC'],
              'IMAGE': image, // data URI (peut être vide)
              'variantes': variantesList
                  .map((v) => {
                        'GA_ARTICLE': v['GA_ARTICLE'],
                        'taille': v['taille'],
                        'couleur': v['couleur'],
                        'depot': v['depot'],
                      })
                  .toList(),
            });

            _messages.add({'sender': 'button', 'article': articlePayload});

            if (image.isNotEmpty) {
              _messages.add({'sender': 'image', 'text': image});
            }
          }
        }
      } else {
        // Type inconnu -> on affiche le texte brut si présent
        _messages.add({'sender': 'bot', 'text': reply.text ?? 'Message reçu.'});
      }
    } catch (e) {
      _messages.add({'sender': 'bot', 'text': 'Erreur: $e'});
    }

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Widget _buildMessage(Map<String, String> msg) {
    if (msg['sender'] == 'image') {
      try {
        final dataUri = msg['text']!;
        final base64Str =
            dataUri.contains(',') ? dataUri.split(',').last : dataUri;
        final bytes = base64Decode(base64Str);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      } catch (_) {
        return const Text('❌ Erreur de chargement de l\'image.');
      }
    }

    if (msg['sender'] == 'button') {
      final article = jsonDecode(msg['article']!);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.shopping_bag),
          label: const Text("Voir l'article"),
          onPressed: () {
            final detailArticle = {
              'GA_CODEARTICLE': article['GA_CODEARTICLE'],
              'GA_LIBELLE': article['GA_LIBELLE'],
              'GA_PVTTC': article['GA_PVTTC'],
              'IMAGE': article['IMAGE'],
              'variantes':
                  List<Map<String, dynamic>>.from(article['variantes'] ?? []),
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(
                  article: detailArticle,
                  allVariants: detailArticle['variantes'],
                ),
              ),
            );
          },
        ),
      );
    }

    final isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg['text'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
