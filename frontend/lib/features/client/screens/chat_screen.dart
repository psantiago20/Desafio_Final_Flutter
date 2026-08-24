import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../chat/providers/chat_provider.dart';
import '../../home/providers/medicos_provider.dart';
import '../../../shared/models/medico_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _selectedChat = 'isis'; // 'isis' ou 'doctor'
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    // A busca inicial já é feita no construtor do Notifier, 
    // mas garantimos que o scroll vá para o final após o build inicial
    _scrollToBottom();
    
    // Marca como lido o chat inicial (Isis)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).setActiveChat('isis');
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    // Para de suprimir notificações quando sair da tela
    ref.read(chatProvider.notifier).setActiveChat('none');
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text, toDoctor: _selectedChat == 'doctor');
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndUploadExam() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      await ref.read(chatProvider.notifier).uploadExam(image.name, bytes);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Trava para evitar gravações acidentais de milissegundos
        if (_recordingStartTime != null) {
          final duration = DateTime.now().difference(_recordingStartTime!);
          if (duration.inMilliseconds < 1500) {
            debugPrint('Gravação muito curta ignorada: ${duration.inMilliseconds}ms');
            await _audioRecorder.stop();
            setState(() => _isRecording = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, segure o botão por pelo menos 2 segundos.')),
            );
            return;
          }
          debugPrint('Duração da gravação: ${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms');
        }

        final path = await _audioRecorder.stop();
        // Pequeno delay para o navegador finalizar o blob
        await Future.delayed(const Duration(milliseconds: 300));
        
        setState(() => _isRecording = false);
        
        if (path != null) {
          debugPrint('Gravado em: $path');
          final response = await http.get(Uri.parse(path));
          final bytes = response.bodyBytes;
          debugPrint('Tamanho do áudio capturado: ${bytes.length} bytes');
          
          if (bytes.length < 500) {
            debugPrint('ERRO: Arquivo muito pequeno (${bytes.length} bytes).');
            return;
          }

          const extension = 'webm';
          await ref.read(chatProvider.notifier).sendAudioMessage(
            'web_audio_${DateTime.now().millisecondsSinceEpoch}.$extension', 
            bytes, 
            toDoctor: _selectedChat == 'doctor'
          );
          _scrollToBottom();
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          // Usando 44.1kHz que é o padrão nativo do Firefox, evitando erros de re-amostragem
          const config = RecordConfig(
            encoder: AudioEncoder.opus,
            numChannels: 1,
            sampleRate: 44100,
            bitRate: 128000,
          );
          
          if (await _audioRecorder.isRecording()) {
            await _audioRecorder.stop();
          }

          debugPrint('Iniciando gravação de alta qualidade (44.1k/128k)...');
          _recordingStartTime = DateTime.now();
          await _audioRecorder.start(config, path: '');
          setState(() => _isRecording = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de microfone negada.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro na gravação: $e');
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na gravação: $e')),
        );
      }
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
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    // Sempre rolar para o final quando novas mensagens chegarem
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    if (kIsWeb) {
      return _buildWeb(messages, isLoading);
    }
    return _buildMobile(messages, isLoading);
  }

  Widget _buildWeb(List<ChatMessage> messages, bool isLoading) {
    final chatState = ref.watch(chatProvider);
    final activeMessages = _selectedChat == 'doctor' ? chatState.doctorMessages : chatState.isisMessages;

    final medicosAsync = ref.watch(medicosProvider);
    String doctorName = chatState.doctorName ?? 'Atendimento Humano';
    String? doctorPhotoUrl = chatState.doctorPhotoUrl;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar estilo WhatsApp
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Conversas',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryBlueDark,
                          child: Text('I', style: TextStyle(color: Colors.white)),
                        ),
                        title: const Text('Isis (Assistente)'),
                        subtitle: Text(
                          chatState.lastIsisMessage ?? 'Atendimento Virtual',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        trailing: chatState.isisUnreadCount > 0 
                          ? Badge(
                              label: Text(chatState.isisUnreadCount.toString()),
                              backgroundColor: Colors.red,
                            )
                          : null,
                        selected: _selectedChat == 'isis',
                        selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        onTap: () {
                          setState(() {
                            _selectedChat = 'isis';
                          });
                          ref.read(chatProvider.notifier).setActiveChat('isis');
                        },
                      ),
                      // Só exibe o atendimento humano se o médico tiver enviado mensagens
                      if (chatState.doctorMessages.isNotEmpty)
                        ListTile(
                          leading: doctorPhotoUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(doctorPhotoUrl!),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Text('M', style: TextStyle(color: Colors.white)),
                                ),
                          title: Text(doctorName),
                          subtitle: Text(
                            chatState.lastDoctorMessage ?? 'Atendimento Humano',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          trailing: chatState.doctorUnreadCount > 0 
                            ? Badge(
                                label: Text(chatState.doctorUnreadCount.toString()),
                                backgroundColor: Colors.red,
                              )
                            : null,
                          selected: _selectedChat == 'doctor',
                          selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          onTap: () {
                            setState(() {
                              _selectedChat = 'doctor';
                            });
                            ref.read(chatProvider.notifier).setActiveChat('doctor');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Área do Chat
          Expanded(
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(chatProvider.notifier).fetchMessages(),
                      child: activeMessages.isEmpty && !isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma mensagem nesta conversa.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16.0),
                              itemCount: activeMessages.length + (isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == activeMessages.length && isLoading) {
                                  return const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.0,
                                        horizontal: 8.0,
                                      ),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final msg = activeMessages[index];
                                return _buildMessageBubble(msg);
                              },
                            ),
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(List<ChatMessage> messages, bool isLoading) {
    final chatState = ref.watch(chatProvider);
    final activeMessages = _selectedChat == 'doctor'
        ? chatState.doctorMessages
        : chatState.isisMessages;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : CustomAppBar(
              subtitle: _selectedChat == 'doctor' ? 'Atendimento Médico' : 'Atendimento por IA',
              showProfileButton: false,
            ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: Column(
          children: [
            // ── Tab switcher (Isis / Doctor) ──────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _mobileTab(
                    label: 'Isis IA',
                    icon: Icons.smart_toy_outlined,
                    value: 'isis',
                    badgeCount: chatState.isisUnreadCount,
                  ),
                  _mobileTab(
                    label: 'Médico',
                    icon: Icons.person_outlined,
                    value: 'doctor',
                    badgeCount: chatState.doctorUnreadCount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Message list ──────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(chatProvider.notifier).fetchMessages(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: activeMessages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == activeMessages.length && isLoading) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 8.0,
                          ),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final msg = activeMessages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
            ),
            // ── Input bar ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _pickAndUploadExam,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _sendMessage,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _toggleRecording,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segmented-control style tab for the mobile chat switcher.
  Widget _mobileTab({
    required String label,
    required IconData icon,
    required String value,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedChat == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedChat = value);
          ref.read(chatProvider.notifier).setActiveChat(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (badgeCount > 0 && !isSelected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final message = msg.text;
    final isMe = msg.isMe;
    final senderName = msg.senderName;

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
          color: isMe ? AppTheme.primaryBlueDark : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : null,
            bottomLeft: !isMe ? const Radius.circular(0) : null,
          ),
          border: isMe ? null : Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe && senderName != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.senderPhotoUrl != null)
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(msg.senderPhotoUrl!),
                    ),
                  if (msg.senderPhotoUrl != null) const SizedBox(width: 4),
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: senderName.contains('Isis') 
                          ? Colors.teal 
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: _pickAndUploadExam,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: AppTheme.primaryBlueDark,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppTheme.primaryBlueDark,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
              onPressed: _toggleRecording,
            ),
          ),
        ],
      ),
    );
  }
}
