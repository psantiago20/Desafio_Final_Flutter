import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/phone_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/medicos_provider.dart';
import '../../../shared/models/medico_model.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime? timestamp;
  final String? senderName;
  final String? senderPhotoUrl;

  const ChatMessage({
    required this.text,
    required this.isMe,
    this.timestamp,
    this.senderName,
    this.senderPhotoUrl,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final List<ChatMessage> isisMessages;
  final List<ChatMessage> doctorMessages;
  final bool isLoading;
  final bool isFetching;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isisMessages = const [],
    this.doctorMessages = const [],
    this.isLoading = false,
    this.isFetching = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatMessage>? isisMessages,
    List<ChatMessage>? doctorMessages,
    bool? isLoading,
    bool? isFetching,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isisMessages: isisMessages ?? this.isisMessages,
      doctorMessages: doctorMessages ?? this.doctorMessages,
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  Timer? _pollTimer;
  int? _patientId;

  ChatNotifier(this.ref) : super(ChatState()) {
    if (state.messages.isEmpty) {
      fetchMessages();
    }
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    if (state.isFetching) return;
    
    state = state.copyWith(isFetching: true);
    try {
      final response = await ApiClient.get('/api/messages');
      final List<dynamic> msgs = response['messages'];

      if (msgs.isNotEmpty) {
        _patientId = msgs.first['patient_id'] as int?;
      }

      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      List<MedicoModel> medicos = [];
      try {
        medicos = await ref.read(medicosProvider.future);
      } catch (e) {
        debugPrint('Erro ao buscar médicos: $e');
      }

      final List<ChatMessage> loadedMessages = [];
      final List<ChatMessage> isisMessages = [];
      final List<ChatMessage> doctorMessages = [];
      
      for (var m in msgs.reversed) {
        final source = m['source'] as String?;
        final waFrom = m['wa_from'] as String?;
        final senderId = m['sender_id'] as int?;
        
        DateTime? ts;
        final rawTs = m['created_at'];
        if (rawTs is String) {
          try {
            ts = DateTime.parse(rawTs);
          } catch (_) {}
        }

        bool isMe = false;
        if (senderId != null) {
          isMe = senderId == currentUserId;
        } else {
          isMe = source == 'app' || source == 'whatsapp';
        }

        String? senderName;
        String? senderPhotoUrl;
        if (!isMe) {
          if (waFrom == 'isis_ia' || source == 'system' || source == 'ai' || source == 'bot') {
            senderName = 'Isis (Assistente)';
          } else {
            senderName = 'Médico';
            if (medicos.isNotEmpty) {
              senderName = medicos.first.nomeCompleto;
              senderPhotoUrl = medicos.first.fotoUrl;
            }
            if (senderId != null) {
              for (var doc in medicos) {
                if (doc.userId == senderId) {
                  senderName = doc.nomeCompleto;
                  senderPhotoUrl = doc.fotoUrl;
                  break;
                }
              }
            }
          }
        }

        final chatMsg = ChatMessage(
          text: m['content'] as String,
          isMe: isMe,
          timestamp: ts,
          senderName: senderName,
          senderPhotoUrl: senderPhotoUrl,
        );

        loadedMessages.add(chatMsg);

        // Separação das mensagens por aba
        if (waFrom == 'isis_ia' || source == 'system' || source == 'ai' || source == 'bot') {
          isisMessages.add(chatMsg);
        } else if (source == 'app_doctor' || senderName == 'Médico' || (senderName != null && senderName != 'Isis (Assistente)')) {
          doctorMessages.add(chatMsg);
        } else if (isMe) {
          if (source == 'app_doctor') {
            doctorMessages.add(chatMsg);
          } else {
            isisMessages.add(chatMsg);
          }
        } else {
          doctorMessages.add(chatMsg);
        }
      }
      
      state = state.copyWith(
        messages: loadedMessages,
        isisMessages: isisMessages,
        doctorMessages: doctorMessages,
        isFetching: false,
      );
    } catch (e) {
      debugPrint('Erro ao buscar mensagens: $e');
      state = state.copyWith(isFetching: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text, {bool toDoctor = false}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isMe: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      if (toDoctor) {
        if (_patientId == null) {
          state = state.copyWith(
            messages: [
              ...state.messages,
              const ChatMessage(
                text: 'Erro: Não foi possível identificar o paciente para enviar a mensagem.',
                isMe: false,
              ),
            ],
            isLoading: false,
          );
          return;
        }
        try {
          await ApiClient.post('/api/messages', {
            'patient_id': _patientId,
            'content': text,
            'message_type': 'text',
            'source': 'app_doctor',
          });
          state = state.copyWith(isLoading: false);
          await fetchMessages();
        } catch (e) {
          final errorMessage = ChatMessage(
            text: 'Erro ao enviar mensagem para o médico: $e',
            isMe: false,
          );
          state = state.copyWith(
            messages: [...state.messages, errorMessage],
            isLoading: false,
          );
        }
        return;
      }

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

final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
