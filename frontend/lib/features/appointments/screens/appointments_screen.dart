import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/appointments_provider.dart';
import '../providers/appointments_live_sync.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/models/appointment_model.dart';
import 'package:frontend/shared/widgets/custom_app_bar.dart';
import 'package:frontend/features/patients/providers/patients_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  static const _statusOptions = [
    (label: 'Todos', value: null),
    (label: 'Pendente', value: 'pending'),
    (label: 'Confirmado', value: 'confirmed'),
    (label: 'Em Andamento', value: 'in_progress'),
    (label: 'Concluído', value: 'completed'),
    (label: 'Cancelado', value: 'cancelled'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appointmentsLiveSyncProvider);
    final filters = ref.watch(appointmentFiltersProvider);
    final appointmentsAsync = ref.watch(appointmentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        subtitle: 'Gerenciamento de Consultas',
        showProfileButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/appointments/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por status
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _statusOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final opt = _statusOptions[i];
                final selected = filters.statusFilter == opt.value;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(appointmentFiltersProvider.notifier)
                        .update(
                          (s) => AppointmentFilters(
                            statusFilter: opt.value,
                            dateFrom: s.dateFrom,
                            dateTo: s.dateTo,
                            doctorId: s.doctorId,
                          ),
                        );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) => appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma consulta encontrada',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          ref.invalidate(appointmentsListProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _AppointmentTile(
                          appointment: appointments[i],
                          onTap: () => context.push(
                            '/appointments/${appointments[i].id}',
                            extra: appointments[i],
                          ),
                        ),
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.cancelled,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar consultas',
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(appointmentsListProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _AppointmentTile({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = statusColor(appointment.status);
    final timeFmt = DateFormat('HH:mm');
    final patientAsync = ref.watch(patientByIdProvider(appointment.patientId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Data
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(appointment.appointmentDate),
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM',
                      'pt_BR',
                    ).format(appointment.appointmentDate).toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  patientAsync.when(
                    data: (patient) => Text(
                      patient.name,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    loading: () => const Text('Carregando...'),
                    error: (_, _) => Text(
                      'Paciente #${appointment.patientId}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFmt.format(appointment.appointmentDate),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.durationMinutes} min',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    typeLabel(appointment.type),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(appointment.status),
                    style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
