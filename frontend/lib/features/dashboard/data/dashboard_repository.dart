import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';

class DashboardRepository {
  Future<DashboardStats> getStats() async {
    final data = await ApiClient.get(AppConstants.dashboardStatsEndpoint);
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AppointmentModel>> getTodayAppointments() async {
    final data = await ApiClient.get(AppConstants.todayAppointmentsEndpoint);
    final list = data as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppointmentModel>> getUpcomingAppointments(
      {int limit = 5}) async {
    final data = await ApiClient.get(
      AppConstants.upcomingAppointmentsEndpoint,
      {'limit': limit},
    );
    final list = data as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
