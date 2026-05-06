import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/appointments_repository.dart';
import '../../../shared/models/appointment_model.dart';

final appointmentsRepositoryProvider =
    Provider<AppointmentsRepository>((_) => AppointmentsRepository());

// Filtros de estado
class AppointmentFilters {
  final String? statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? doctorId;

  const AppointmentFilters({
    this.statusFilter,
    this.dateFrom,
    this.dateTo,
    this.doctorId,
  });

  AppointmentFilters copyWith({
    String? statusFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? doctorId,
    bool clearStatus = false,
  }) {
    return AppointmentFilters(
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      doctorId: doctorId ?? this.doctorId,
    );
  }
}

final appointmentFiltersProvider =
    StateProvider<AppointmentFilters>((_) => const AppointmentFilters());

final appointmentsListProvider =
    FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  final filters = ref.watch(appointmentFiltersProvider);
  return ref.read(appointmentsRepositoryProvider).getAppointments(
        doctorId: filters.doctorId,
        statusFilter: filters.statusFilter,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
      );
});

// Provider para ação de update de status
class AppointmentActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppointmentsRepository _repository;

  AppointmentActionsNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<AppointmentModel?> updateStatus(int id, String status) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateStatus(id, status);
      state = const AsyncValue.data(null);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AppointmentModel?> updateAppointment(
      int id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateAppointment(id, updates);
      state = const AsyncValue.data(null);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteAppointment(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAppointment(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final appointmentActionsProvider =
    StateNotifierProvider<AppointmentActionsNotifier, AsyncValue<void>>(
  (ref) =>
      AppointmentActionsNotifier(ref.read(appointmentsRepositoryProvider)),
);
