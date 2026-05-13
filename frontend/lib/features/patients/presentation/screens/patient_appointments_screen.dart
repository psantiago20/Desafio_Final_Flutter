import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../appointments/providers/appointments_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/models/patient_model.dart';

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  final PatientModel patient;
  const PatientAppointmentsScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends ConsumerState<PatientAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Set the filter for this specific patient
    Future.microtask(() {
      ref.read(appointmentFiltersProvider.notifier).update(
        (s) => s.copyWith(patientId: widget.patient.id, clearStatus: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Consultas de ${widget.patient.name}',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Clear the patient filter when leaving
            ref.read(appointmentFiltersProvider.notifier).update(
              (s) => s.copyWith(clearPatient: true),
            );
            context.pop();
          },
        ),
      ),
      body: appointmentsAsync.when(
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
                onRefresh: () async => ref.invalidate(appointmentsListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AppointmentTile(
                    appointment: appointments[i],
                    patientName: widget.patient.name,
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
          child: Text('Erro ao carregar consultas'),
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  final String patientName;
  final VoidCallback onTap;

  const _AppointmentTile({
    required this.appointment,
    required this.patientName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(appointment.status);
    final timeFmt = DateFormat('HH:mm');

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
                color: AppColors.primary.withOpacity(0.08),
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
                    DateFormat('MMM', 'pt_BR').format(appointment.appointmentDate).toUpperCase(),
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
                  Text(
                    patientName,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        timeFmt.format(appointment.appointmentDate),
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.durationMinutes} min',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
          ],
        ),
      ),
    );
  }
}
