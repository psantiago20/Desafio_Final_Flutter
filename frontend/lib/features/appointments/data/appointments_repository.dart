import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/appointment_model.dart';

class AppointmentsRepository {
  Future<List<AppointmentModel>> getAppointments({
    int? doctorId,
    String? statusFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    int skip = 0,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      'doctor_id': ?doctorId,
      'status_filter': ?statusFilter,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
    };

    final data = await ApiClient.get(AppConstants.appointmentsEndpoint, params);
    final map = data as Map<String, dynamic>;
    final list = map['appointments'] as List<dynamic>;
    return list
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentModel> getAppointment(int id) async {
    final data = await ApiClient.get(
      '${AppConstants.appointmentsEndpoint}/$id',
    );
    return AppointmentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AppointmentModel> createAppointment({
    required int patientId,
    required int doctorId,
    required DateTime date,
    int durationMinutes = 30,
    String type = 'consultation',
    String? reason,
    double price = 0.0,
  }) async {
    final data = await ApiClient.post(AppConstants.appointmentsEndpoint, {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'type': type,
      'reason': ?reason,
      'price': price,
    });
    return AppointmentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AppointmentModel> updateStatus(int id, String status) async {
    final data = await ApiClient.patch(
      '${AppConstants.appointmentsEndpoint}/$id/status',
      {'status': status},
    );
    return AppointmentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AppointmentModel> updateAppointment(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final data = await ApiClient.put(
      '${AppConstants.appointmentsEndpoint}/$id',
      updates,
    );
    return AppointmentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAppointment(int id) async {
    await ApiClient.delete('${AppConstants.appointmentsEndpoint}/$id');
  }
}
