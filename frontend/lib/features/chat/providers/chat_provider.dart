import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/utils/token_storage.dart';
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
  final int isisUnreadCount;
  final int doctorUnreadCount;
  final int totalUnreadCount;
  final bool isLoading;
  final bool isFetching;
  final String? error;
  final int? patientId;
  final String activeChat; // 'none', 'isis', 'doctor'
  final String? lastIsisMessage;
  final String? lastDoctorMessage;
  final String? doctorName;
  final String? doctorPhotoUrl;

  ChatState({
    this.messages = const [],
    this.isisMessages = const [],
    this.doctorMessages = const [],
    this.isisUnreadCount = 0,
    this.doctorUnreadCount = 0,
    this.totalUnreadCount = 0,
    this.isLoading = false,
    this.isFetching = false,
    this.error,
    this.patientId,
    this.activeChat = 'none',
    this.lastIsisMessage,
    this.lastDoctorMessage,
    this.doctorName,
    this.doctorPhotoUrl,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatMessage>? isisMessages,
    List<ChatMessage>? doctorMessages,
    int? isisUnreadCount,
    int? doctorUnreadCount,
    int? totalUnreadCount,
    bool? isLoading,
    bool? isFetching,
    String? error,
    int? patientId,
    String? activeChat,
    String? lastIsisMessage,
    String? lastDoctorMessage,
    String? doctorName,
    String? doctorPhotoUrl,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isisMessages: isisMessages ?? this.isisMessages,
      doctorMessages: doctorMessages ?? this.doctorMessages,
      isisUnreadCount: isisUnreadCount ?? this.isisUnreadCount,
      doctorUnreadCount: doctorUnreadCount ?? this.doctorUnreadCount,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      error: error ?? this.error,
      patientId: patientId ?? this.patientId,
      activeChat: activeChat ?? this.activeChat,
      lastIsisMessage: lastIsisMessage ?? this.lastIsisMessage,
      lastDoctorMessage: lastDoctorMessage ?? this.lastDoctorMessage,
      doctorName: doctorName ?? this.doctorName,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
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
    // Se estiver enviando algo ou já buscando, não faz nada para evitar 'atropelar' o estado local
    if (state.isFetching || state.isLoading) return;
    
    if (!mounted) return;
    state = state.copyWith(isFetching: true);
    try {
      final response = await ApiClient.get('/api/messages');
      
      // VERIFICAÇÃO DUPLA: Se o usuário começou a enviar um áudio enquanto a rede buscava as mensagens,
      // nós abortamos a atualização para não apagar o 'Enviando...' da tela.
      if (state.isLoading || !mounted) return;

      final List<dynamic> msgs = response['messages'];

      int patientId = 0;
      if (msgs.isNotEmpty) {
        patientId = (msgs.first['patient_id'] as int?) ?? 0;
        _patientId = patientId;
      }

      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final medicosAsync = ref.read(medicosProvider);
      final List<MedicoModel> medicos = medicosAsync.value ?? [];

      final List<ChatMessage> loadedMessages = [];
      final List<ChatMessage> isisMessages = [];
      final List<ChatMessage> doctorMessages = [];
      
      int isisUnread = 0;
      int doctorUnread = 0;

      for (var m in msgs.reversed) {
        final source = m['source'] as String?;
        final waFrom = m['wa_from'] as String?;
        final senderId = m['sender_id'] as int?;
        final isRead = m['is_read'] as bool? ?? true;
        
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
        } else if (source == 'app') {
          isMe = true; 
        } else if (source == 'whatsapp') {
          // Mensagens vindas do webhook do WhatsApp são do paciente.
          // Se quem está vendo for o paciente, isMe = true. Se for médico, isMe = false.
          final role = authState.user?.role;
          isMe = (role == 'patient' || role == 'paciente');
        } else {
          isMe = false;
        }

        String? senderName;
        String? senderPhotoUrl;
        if (!isMe) {
          if (waFrom == 'isis_ia' || source == 'system' || source == 'ai' || source == 'bot') {
            senderName = 'Isis (Assistente)';
          } else {
            senderName = 'Médico';
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
          text: (m['content'] as String?) ?? '',
          isMe: isMe,
          timestamp: ts,
          senderName: senderName,
          senderPhotoUrl: senderPhotoUrl,
        );

        loadedMessages.add(chatMsg);

        // Separação das mensagens por aba e contagem de não lidas
        // Mensagem é de médico SOMENTE se source='app_doctor' ou se foi enviada por um usuário médico
        final isExplicitlyDoctor = source == 'app_doctor' || 
                                   (!isMe && senderName != null && senderName != 'Isis (Assistente)');

        // Mensagem é da Isis se: veio da IA, é do sistema, ou é do próprio paciente (exceto se enviado para o médico)
        final isIsis = (waFrom == 'isis_ia' || 
                       source == 'system' || source == 'ai' || source == 'bot' ||
                       (!isMe && senderName == 'Isis (Assistente)') ||
                       isMe) && source != 'app_doctor';

        final isDoctor = isExplicitlyDoctor && !isIsis;

        if (isIsis) {
          isisMessages.add(chatMsg);
          if (!isMe && !isRead) isisUnread++;
        } else {
          // Por padrão vai para médico se não for claramente Isis
          doctorMessages.add(chatMsg);
          if (!isMe && !isRead) doctorUnread++;
        }
      }
      
      // Suprime contagem para o chat ativo para evitar "piscar"
      if (state.activeChat == 'isis') isisUnread = 0;
      if (state.activeChat == 'doctor') doctorUnread = 0;

        // Extração do nome/foto do médico para a UI
        String? doctorName;
        String? doctorPhotoUrl;
        if (doctorMessages.isNotEmpty) {
          for (var m in doctorMessages) {
            if (!m.isMe && m.senderName != null && m.senderName != 'Médico') {
              doctorName = m.senderName;
              doctorPhotoUrl = m.senderPhotoUrl;
              break;
            }
          }
        }

        if (!mounted) return;
        state = state.copyWith(
          messages: loadedMessages,
          isisMessages: isisMessages,
          doctorMessages: doctorMessages,
          isisUnreadCount: isisUnread,
          doctorUnreadCount: doctorUnread,
          totalUnreadCount: isisUnread + doctorUnread,
          isFetching: false,
          patientId: patientId,
          lastIsisMessage: isisMessages.isNotEmpty ? isisMessages.last.text : null,
          lastDoctorMessage: doctorMessages.isNotEmpty ? doctorMessages.last.text : null,
          doctorName: doctorName,
          doctorPhotoUrl: doctorPhotoUrl,
        );
      
      // Auto-mark as read if a chat is active
      if (state.activeChat == 'isis' && isisUnread > 0) markAsRead(false);
      if (state.activeChat == 'doctor' && doctorUnread > 0) markAsRead(true);
    } catch (e) {
      debugPrint('Erro ao buscar mensagens: $e');
      if (!mounted) return;
      state = state.copyWith(isFetching: false, isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text, {bool toDoctor = false}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isMe: true);
    if (!mounted) return;
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isisMessages: toDoctor ? state.isisMessages : [...state.isisMessages, userMessage],
      doctorMessages: toDoctor ? [...state.doctorMessages, userMessage] : state.doctorMessages,
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
            doctorMessages: [
              ...state.doctorMessages,
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
          if (!mounted) return;
          state = state.copyWith(isLoading: false);
          fetchMessages(); // Não dar await aqui para liberar a UI
        } catch (e) {
          final errorMessage = ChatMessage(
            text: 'Erro ao enviar mensagem para o médico: $e',
            isMe: false,
          );
          state = state.copyWith(
            messages: [...state.messages, errorMessage],
            doctorMessages: [...state.doctorMessages, errorMessage],
            isLoading: false,
          );
        }
        return;
      }

      final authState = ref.read(authProvider);
      final waFrom = canonicalWaFrom(authState.user?.phone);
      if (waFrom.isEmpty) {
        final errorMsg = const ChatMessage(
          text: 'Cadastre seu telefone no perfil para sincronizar o chat com o WhatsApp.',
          isMe: false,
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isisMessages: [...state.isisMessages, errorMsg],
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
      if (!mounted) return;
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isisMessages: [...state.isisMessages, aiMessage],
        isLoading: false,
      );
      fetchMessages(); // Não dar await aqui para liberar a UI
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Erro de conexão: Não foi possível contatar o assistente virtual.',
        isMe: false,
      );
      if (!mounted) return;
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isisMessages: [...state.isisMessages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<void> uploadExam(String fileName, Uint8List bytes) async {
    final userMessage = ChatMessage(text: 'Enviando exame ($fileName)...', isMe: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isisMessages: [...state.isisMessages, userMessage],
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

      final token = TokenStorage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

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
        final cleanMessages = state.messages
            .where((m) => !m.text.contains('Enviando exame'))
            .toList();
        final cleanIsis = state.isisMessages
            .where((m) => !m.text.contains('Enviando exame'))
            .toList();
        state = state.copyWith(
          messages: [...cleanMessages, aiMessage],
          isisMessages: [...cleanIsis, aiMessage],
          isLoading: false,
        );
        fetchMessages(); // Não dar await aqui para liberar a UI
      } else {
        final cleanMessages = state.messages
            .where((m) => !m.text.contains('Enviando exame'))
            .toList();
        final cleanIsis = state.isisMessages
            .where((m) => !m.text.contains('Enviando exame'))
            .toList();
        final errorMessage = ChatMessage(
          text: 'Erro ao enviar o exame. Tente novamente.',
          isMe: false,
        );
        state = state.copyWith(
          messages: [...cleanMessages, errorMessage],
          isisMessages: [...cleanIsis, errorMessage],
          isLoading: false,
        );
      }
    } catch (e) {
      final cleanMessages = state.messages
          .where((m) => !m.text.contains('Enviando exame'))
          .toList();
      final cleanIsis = state.isisMessages
          .where((m) => !m.text.contains('Enviando exame'))
          .toList();
      final errorMessage = ChatMessage(
        text: 'Erro ao enviar a imagem: $e',
        isMe: false,
      );
      state = state.copyWith(
        messages: [...cleanMessages, errorMessage],
        isisMessages: [...cleanIsis, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<void> sendAudioMessage(String fileName, Uint8List bytes, {bool toDoctor = false}) async {
    final userMessage = ChatMessage(text: 'Enviando áudio ($fileName)...', isMe: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isisMessages: toDoctor ? state.isisMessages : [...state.isisMessages, userMessage],
      doctorMessages: toDoctor ? [...state.doctorMessages, userMessage] : state.doctorMessages,
      isLoading: true,
    );

    try {
      final authState = ref.read(authProvider);
      final waFrom = canonicalWaFrom(authState.user?.phone);
      if (waFrom.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/rag/audio-query');
      var request = http.MultipartRequest('POST', url);
      request.fields['wa_from'] = waFrom;
      request.fields['source'] = 'app';
      
      final token = TokenStorage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final isWav = fileName.endsWith('.wav');
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: fileName,
          contentType: isWav ? MediaType('audio', 'wav') : MediaType('audio', 'webm'),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final transcribedMsg = ChatMessage(text: data['query'] as String, isMe: true);
        final aiMessage = ChatMessage(text: data['response'] as String, isMe: false);
        
        final cleanAll = state.messages.where((m) => !m.text.contains('Enviando')).toList();
        final cleanIsis = state.isisMessages.where((m) => !m.text.contains('Enviando')).toList();
        final cleanDoctor = state.doctorMessages.where((m) => !m.text.contains('Enviando')).toList();

        state = state.copyWith(
          messages: [...cleanAll, transcribedMsg, aiMessage],
          isisMessages: toDoctor ? cleanIsis : [...cleanIsis, transcribedMsg, aiMessage],
          doctorMessages: toDoctor ? [...cleanDoctor, transcribedMsg, aiMessage] : cleanDoctor,
          isLoading: false,
        );
      } else {
        debugPrint('Erro no envio de áudio: ${response.statusCode} - $responseBody');
        final cleanIsis = state.isisMessages.where((m) => !m.text.contains('Enviando')).toList();
        state = state.copyWith(
          isisMessages: cleanIsis,
          isLoading: false
        );
      }
    } catch (e) {
      debugPrint('Exceção no envio de áudio: $e');
      final cleanIsis = state.isisMessages.where((m) => !m.text.contains('Enviando')).toList();
      state = state.copyWith(
        isisMessages: cleanIsis,
        isLoading: false
      );
    }
  }

  Future<void> markAsRead(bool isDoctor) async {
    final patientId = state.patientId ?? _patientId;
    if (patientId == null) return;

    try {
      // Por enquanto marcamos todas do paciente como lidas
      // O backend já faz isso no endpoint que criamos
      await ApiClient.patch('/api/messages/read-all/$patientId', {});
      
      // Atualiza localmente para feedback imediato
      if (isDoctor) {
        state = state.copyWith(
          doctorUnreadCount: 0,
          totalUnreadCount: state.isisUnreadCount,
        );
      } else {
        state = state.copyWith(
          isisUnreadCount: 0,
          totalUnreadCount: state.doctorUnreadCount,
        );
      }
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }

  void setActiveChat(String chat) {
    state = state.copyWith(activeChat: chat);
    if (chat == 'isis') markAsRead(false);
    if (chat == 'doctor') markAsRead(true);
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
