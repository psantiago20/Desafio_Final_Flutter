import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((_) => DashboardRepository());

// Stats
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) {
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
  return ref.read(dashboardRepositoryProvider).getUpcomingAppointments();
});
