import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'dart:async';

class DoctorMessagesScreen extends ConsumerStatefulWidget {
  final int? initialPatientId;
  final String? initialPatientName;
  
  const DoctorMessagesScreen({
    super.key,
    this.initialPatientId,
    this.initialPatientName,
  });

  @override
  ConsumerState<DoctorMessagesScreen> createState() =>
      _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends ConsumerState<DoctorMessagesScreen> {
  bool _isSidebarOpen = true;
  int? _selectedPatientId;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _refreshTimer;

  final List<Map<String, dynamic>> _patients = [
    {
      'id': 0,
      'name': 'Isis (Assistente)',
      'lastMessage': 'Olá Doutor, como posso ajudar?',
      'time': '09:00',
      'hasChat': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadConversations();
        if (_selectedPatientId != null) {
          _loadMessages(_selectedPatientId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isAssistantMessage(Map<String, dynamic> message) {
    final source = message['source'];
    final waFrom = message['wa_from'];
    return waFrom == 'isis_ia' ||
        waFrom == 'system' ||
        waFrom == 'BOT' ||
        source == 'system' ||
        source == 'bot' ||
        source == 'ai';
  }

  bool _isDirectDoctorPatientMessage(
    Map<String, dynamic> message,
    int? currentUserId,
  ) {
    if (_isAssistantMessage(message)) return false;

    final senderId = message['sender_id'];
    final receiverId = message['receiver_id'];
    final source = message['source'];

    return source == 'app_doctor' ||
        senderId == currentUserId ||
        receiverId == currentUserId;
  }

  Future<void> _loadConversations() async {
    try {
      final response = await ApiClient.get('/api/messages');
      final List<dynamic> msgs = response['messages'];
      
      final Map<int, Map<String, dynamic>> conversations = {};
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      for (final m in msgs) {
        final patientId = m['patient_id'];
        if (patientId != null) {
          final message = m as Map<String, dynamic>;
          if (patientId != 15 &&
              !_isDirectDoctorPatientMessage(message, currentUserId)) {
            continue;
          }
          }

          final patient = m['patient'];
          final name = patient != null ? patient['name'] : 'Paciente $patientId';
          
          if (!conversations.containsKey(patientId)) {
            String timeStr = '...';
            try {
              // Ajuste para Horário de Brasília: Backend envia UTC sem 'Z', forçamos e convertemos
              final dt = DateTime.parse("${m['created_at']}Z").toLocal();
              timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            } catch (e) {}
            
            conversations[patientId] = {
              'id': patientId,
              'name': name,
              'lastMessage': m['content'],
              'time': timeStr,
              'hasChat': true,
              'unreadCount': 0,
            };
          }
          
          // Contagem de não lidas
          final isFromMe = m['sender_id'] == currentUserId;
          final isRead = m['is_read'] == true;
          
          if (!isRead &&
              !isFromMe &&
              patientId != 15 &&
              !_isAssistantMessage(message) &&
              (source == 'app_doctor' ||
                  source == 'whatsapp' ||
                  m['sender_id'] != null)) {
            conversations[patientId]!['unreadCount'] = (conversations[patientId]!['unreadCount'] as int) + 1;
          }
        }
      }
      
      setState(() {
        final List<Map<String, dynamic>> patientsList = [];
        
        // Mapeia Isis (ID 15 no backend) para ID 0 no frontend
        if (conversations.containsKey(15)) {
          final isis = conversations[15]!;
          isis['id'] = 0;
          patientsList.add(isis);
          conversations.remove(15);
        } else {
          patientsList.add({
            'id': 0,
            'name': 'Isis (Assistente)',
            'lastMessage': 'Olá Doutor, como posso ajudar?',
            'time': '09:00',
            'hasChat': true,
          });
        }
        
        // Adiciona os outros
        patientsList.addAll(conversations.values.cast<Map<String, dynamic>>());
        
        _patients.clear();
        _patients.addAll(patientsList);
        
        // Handle initial patient selection
        if (widget.initialPatientId != null) {
          final exists = _patients.any((p) => p['id'] == widget.initialPatientId);
          if (!exists && widget.initialPatientName != null) {
            _patients.add({
              'id': widget.initialPatientId!,
              'name': widget.initialPatientName!,
              'lastMessage': '',
              'time': '',
              'hasChat': true,
            });
          }
          _selectedPatientId = widget.initialPatientId;
          _loadMessages(widget.initialPatientId!);
        }
      });
    } catch (e) {
      print('Erro ao carregar conversas: $e');
    }
  }

  final Map<int, List<Map<String, dynamic>>> _messagesByPatient = {
    0: [
      {'sender': 'isis', 'text': 'Olá Doutor, como posso ajudar?', 'time': '09:00'},
    ],
    13: [],
    1: [],
    2: [],
  };

  bool _isLoadingMessages = false;

  Future<void> _loadMessages(int patientId) async {
    setState(() {
      _isLoadingMessages = true;
    });
    try {
      final targetId = patientId == 0 ? 15 : patientId;
      final response = await ApiClient.get('/api/messages?patient_id=$targetId');
      final List<dynamic> msgs = response['messages'];
      
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      // Marcar todas como lidas no backend
      try {
        await ApiClient.patch('/api/messages/read-all/$targetId', {});
        // Atualiza localmente a contagem de não lidas na lista de pacientes
        setState(() {
          final pIndex = _patients.indexWhere((p) => p['id'] == patientId);
          if (pIndex != -1) {
            _patients[pIndex]['unreadCount'] = 0;
          }
        });
      } catch (e) {
        print('Erro ao marcar mensagens como lidas: $e');
      }

      setState(() {
        final filteredMsgs = patientId == 0
            ? msgs
            : msgs
                .where(
                  (m) => _isDirectDoctorPatientMessage(
                    m as Map<String, dynamic>,
                    currentUserId,
                  ),
                )
                .toList();

        _messagesByPatient[patientId] = filteredMsgs.map((m) {
          final content = m['content'];
          final waFrom = m['wa_from'];
          final senderId = m['sender_id'];
          
          String sender = 'patient';
          final source = m['source'];
          // Mensagens da Isis/IA: qualquer source de IA, bot, system ou wa_from isis_ia
          final isIsisMessage = waFrom == 'isis_ia' ||
              source == 'system' ||
              source == 'bot' ||
              source == 'ai';
          // source=app_doctor indica o canal paciente-medico; sender_id indica quem enviou.
          final isDoctorMessage = senderId == currentUserId;
          if (isIsisMessage) {
            sender = 'isis';
          } else if (isDoctorMessage) {
            sender = 'doctor';
          } else if (patientId == 0) {
            sender = 'doctor';
          }
          
          String timeStr = '...';
          try {
            // Ajuste para Horário de Brasília
            final dt = DateTime.parse("${m['created_at']}Z").toLocal();
            timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } catch (e) {
            // fallback
          }
          
          return {
            'sender': sender,
            'text': content,
            'time': timeStr,
          };
        }).toList().reversed.toList();
        
        // Se a lista estiver vazia e for a Isis, adiciona a mensagem padrão
        if (patientId == 0 && _messagesByPatient[0]!.isEmpty) {
          _messagesByPatient[0]!.add({'sender': 'isis', 'text': 'Olá Doutor, como posso ajudar?', 'time': '09:00'});
        }
        
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _startChat(int patientId) {
    setState(() {
      final patient = _patients.firstWhere((p) => p['id'] == patientId);
      patient['hasChat'] = true;
      _selectedPatientId = patientId;
    });
    _loadMessages(patientId);
  }

  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_isSending) return;
    if (_msgController.text.trim().isEmpty) return;
    if (_selectedPatientId == null) return;
    
    setState(() {
      _isSending = true;
    });
    
    final text = _msgController.text.trim();
    final patientId = _selectedPatientId!;
    
    setState(() {
      _messagesByPatient[patientId]?.add({
        'sender': 'doctor',
        'text': text,
        'time': 'Agora',
      });
      _msgController.clear();
    });
    _scrollToBottom();
    
    if (patientId == 0) {
      try {
        final response = await ApiClient.post('/api/chat/ia', {
          'message': text,
          'patient_id': null,
          'source': 'doctor',
        });
        
        setState(() {
          _messagesByPatient[0]?.add({
            'sender': 'isis',
            'text': response['response'],
            'time': 'Agora',
          });
          // Atualiza última mensagem na barra lateral
          final isis = _patients.firstWhere((p) => p['id'] == 0);
          isis['lastMessage'] = response['response'];
          isis['time'] = 'Agora';
        });
        _scrollToBottom();
      } catch (e) {
        setState(() {
          _messagesByPatient[0]?.add({
            'sender': 'isis',
            'text': 'Desculpe, tive um erro ao processar. 😅',
            'time': 'Agora',
          });
        });
        _scrollToBottom();
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    } else {
      try {
        await ApiClient.post('/api/messages', {
          'patient_id': patientId,
          'content': text,
          'message_type': 'text',
          'source': 'app',
        });
      } catch (e) {
        print('Erro ao enviar mensagem: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final showSidebar = isDesktop
        ? _isSidebarOpen
        : (_selectedPatientId == null || _isSidebarOpen);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          if (showSidebar)
            Container(
              width: isDesktop ? 320 : MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conversas',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isDesktop)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleSidebar,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Pesquisar paciente...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _patients.length,
                      itemBuilder: (context, index) {
                        final p = _patients[index];
                        final isSelected = p['id'] == _selectedPatientId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryLight.withOpacity(
                            0.2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              p['name'].substring(0, 1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            p['name'],
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: p['hasChat']
                              ? Text(
                                  p['lastMessage'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : const Text(
                                  'Iniciar conversa',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (p['hasChat'])
                                Text(
                                  p['time'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (p['unreadCount'] != null && p['unreadCount'] > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    p['unreadCount'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            if (!isDesktop) {
                              setState(() => _isSidebarOpen = false);
                            }
                            _startChat(p['id']);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Main Chat Area
          if (!showSidebar || isDesktop)
            Expanded(
              child: _selectedPatientId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Selecione um paciente para conversar',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!showSidebar)
                            TextButton.icon(
                              onPressed: _toggleSidebar,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Voltar para contatos'),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Chat Header
                        Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (!isDesktop || !_isSidebarOpen)
                                IconButton(
                                  icon: Icon(isDesktop ? Icons.menu : Icons.arrow_back),
                                  onPressed: _toggleSidebar,
                                  color: AppColors.textPrimary,
                                ),
                              CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  _patients
                                      .firstWhere(
                                        (p) => p['id'] == _selectedPatientId,
                                      )['name']
                                      .substring(0, 1),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _patients.firstWhere(
                                  (p) => p['id'] == _selectedPatientId,
                                )['name'],
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                                onPressed: () {
                                  if (_selectedPatientId != null) {
                                    _loadMessages(_selectedPatientId!);
                                  }
                                },
                                tooltip: 'Atualizar histórico',
                              ),
                            ],
                          ),
                        ),

                        // Messages List
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                            ),
                            child: _isLoadingMessages
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    controller: _chatScrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messagesByPatient[_selectedPatientId!]?.length ?? 0,
                              itemBuilder: (context, index) {
                                final msg = _messagesByPatient[_selectedPatientId!]![index];
                                final sender = msg['sender'];
                                final isDoctor = sender == 'doctor';
                                final isIsis = sender == 'isis';
                                final isPatient = sender == 'patient';
                                final isOutgoing = isDoctor || (isIsis && _selectedPatientId != 0);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: isOutgoing
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isOutgoing) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isIsis
                                              ? AppColors.primary
                                              : AppColors.surfaceVariant,
                                          child: isIsis
                                              ? const Icon(
                                                  Icons.smart_toy,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDoctor
                                                ? AppTheme.primaryBlueDark
                                                : (isIsis && _selectedPatientId != 0)
                                                    ? AppColors.primary
                                                    : AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(
                                                  16,
                                                ).copyWith(
                                                  bottomRight: isOutgoing
                                                      ? const Radius.circular(0)
                                                      : null,
                                                  bottomLeft: !isOutgoing
                                                      ? const Radius.circular(0)
                                                      : null,
                                                ),
                                            border: isOutgoing
                                                ? null
                                                : Border.all(
                                                    color: AppColors.border,
                                                  ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                  ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isOutgoing
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              if (!isDoctor)
                                                Text(
                                                  isIsis
                                                      ? 'Isis (Assistente)'
                                                      : (_patients.firstWhere((p) => p['id'] == _selectedPatientId, orElse: () => {'name': 'Paciente'})['name']),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isIsis
                                                        ? (isOutgoing ? Colors.white70 : AppColors.primary)
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                msg['text'],
                                                style: TextStyle(
                                                  color: isOutgoing
                                                      ? Colors.white
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                msg['time'],
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isOutgoing
                                                      ? Colors.white70
                                                      : AppColors.textHint,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isOutgoing) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isDoctor
                                              ? AppTheme.primaryBlueDark
                                              : AppColors.primary,
                                          child: Icon(
                                            isDoctor ? Icons.local_hospital : Icons.smart_toy,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Input Area
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.attach_file,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {},
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Digite uma mensagem para o paciente...',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                                  onPressed: _sendMessage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
