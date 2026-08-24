import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((_) => DashboardRepository());

// Navigation state for doctor's desktop dashboard
final doctorNavIndexProvider = StateProvider<int>((ref) => 0);

// Stats
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) {
  // Atualizar automaticamente a cada 30 segundos
  final link = ref.keepAlive();
  final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
    link.close();
  });

  return ref.read(dashboardRepositoryProvider).getStats();
});

// Consultas de hoje
final todayAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.read(dashboardRepositoryProvider).getTodayAppointments();
});

// Próximas consultas
final upcomingAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  // Atualizar automaticamente a cada 30 segundos
  final link = ref.keepAlive();
  final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
    link.close();
  });

  return ref.read(dashboardRepositoryProvider).getUpcomingAppointments();
});

