import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/chat_provider.dart';
import 'appointments_provider.dart';

/// Mantém a lista de consultas alinhada com o servidor (ex.: agendamento via WhatsApp).
final appointmentsLiveSyncProvider = Provider.autoDispose<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 12), (_) {
    ref.invalidate(appointmentsListProvider);
  });
  ref.onDispose(timer.cancel);
});

/// Mantém o histórico de mensagens alinhado com o servidor (ex.: mensagens recebidas no WhatsApp).
final chatLiveSyncProvider = Provider.autoDispose<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 6), (_) {
    ref.read(chatProvider.notifier).fetchMessages();
  });
  ref.onDispose(timer.cancel);
});
