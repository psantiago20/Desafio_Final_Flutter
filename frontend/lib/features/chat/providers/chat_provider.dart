import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/phone_utils.dart';
import '../../auth/providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime? timestamp;

  const ChatMessage({
    required this.text,
    required this.isMe,
    this.timestamp,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isFetching;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isFetching = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isFetching,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(ChatState()) {
    // Carregar mensagens iniciais apenas se ainda não foram carregadas
    if (state.messages.isEmpty) {
      fetchMessages();
    }
  }

  Future<void> fetchMessages() async {
    if (state.isFetching) return;
    
    state = state.copyWith(isFetching: true);
    try {
      final response = await ApiClient.get('/api/messages');
      final List<dynamic> msgs = response['messages'];

      final List<ChatMessage> loadedMessages = [];
      for (var m in msgs.reversed) {
        final source = m['source'] as String?;
        DateTime? ts;
        final rawTs = m['created_at'];
        if (rawTs is String) {
          try {
            ts = DateTime.parse(rawTs);
          } catch (_) {}
        }
        loadedMessages.add(
          ChatMessage(
            text: m['content'] as String,
            isMe: source == 'app' || source == 'whatsapp',
            timestamp: ts,
          ),
        );
      }
      
      state = state.copyWith(messages: loadedMessages, isFetching: false);
    } catch (e) {
      debugPrint('Erro ao buscar mensagens: $e');
      state = state.copyWith(isFetching: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isMe: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final authState = ref.read(authProvider);
      final waFrom = canonicalWaFrom(authState.user?.phone);
      if (waFrom.isEmpty) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            const ChatMessage(
              text:
                  'Cadastre seu telefone no perfil para sincronizar o chat com o WhatsApp.',
              isMe: false,
            ),
          ],
          isLoading: false,
        );
        return;
      }

      final response = await ApiClient.post('/api/rag/query', {
        'query': text,
        'wa_from': waFrom,
        'source': 'app',
      });

      final aiMessage = ChatMessage(text: response['response'] as String, isMe: false);
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
      await fetchMessages();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Erro de conexão: Não foi possível contatar o assistente virtual.',
        isMe: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<void> uploadExam(String fileName, Uint8List bytes) async {
    final userMessage = ChatMessage(text: 'Enviando exame ($fileName)...', isMe: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final authState = ref.read(authProvider);
      final waFrom = canonicalWaFrom(authState.user?.phone);
      if (waFrom.isEmpty) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(
              text:
                  'Cadastre seu telefone no perfil para sincronizar o envio de exames com o WhatsApp.',
              isMe: false,
            ),
          ],
          isLoading: false,
        );
        return;
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/rag/upload-exam');
      var request = http.MultipartRequest('POST', url);
      request.fields['wa_from'] = waFrom;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final aiMessage = ChatMessage(
          text: data['message'] ?? 'Exame processado com sucesso!',
          isMe: false,
        );
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
        await fetchMessages();
      } else {
        final errorMessage = ChatMessage(
          text: 'Erro ao enviar o exame. Tente novamente.',
          isMe: false,
        );
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isLoading: false,
        );
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Erro ao enviar a imagem: $e',
        isMe: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
