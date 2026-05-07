import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class ChatMessage {
  final String text;
  final bool isMe;

  ChatMessage({required this.text, required this.isMe});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Olá! Eu sou a inteligência artificial do aplicativo Sua Consulta. Como posso te ajudar hoje?',
      isMe: false,
    ),
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final url = Uri.parse('http://localhost:8000/api/rag/query');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': text,
          'wa_from': '5511999999999', // Simula um ID do cliente para a IA lembrar o contexto da conversa
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add(ChatMessage(text: data['response'], isMe: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: 'Erro ao comunicar com a IA. Código: ${response.statusCode}', isMe: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Erro de conexão: O servidor da IA parece estar offline.', isMe: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Atendimento por IA',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg.text, msg.isMe);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.only(
          bottom: 16,
          left: isMe ? 40 : 0,
          right: isMe ? 0 : 40,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlueDark : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : null,
            bottomLeft: !isMe ? const Radius.circular(0) : null,
          ),
          border: isMe ? null : Border.all(color: AppTheme.borderGray),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(top: BorderSide(color: AppTheme.borderGray)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundGray,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlueDark,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
