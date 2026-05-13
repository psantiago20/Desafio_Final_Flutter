import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/appointments_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/models/appointment_model.dart';
import 'package:frontend/features/patients/providers/patients_provider.dart';
import 'package:frontend/shared/models/patient_model.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late AppointmentModel _appointment;
  final _symptomsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _symptomsCtrl.text = _appointment.symptoms ?? '';
    _diagnosisCtrl.text = _appointment.diagnosis ?? '';
    _prescriptionCtrl.text = _appointment.prescription ?? '';
    // Weight and height might not be in the model yet, using placeholders or parsing from notes if needed
    _weightCtrl.text = ''; 
    _heightCtrl.text = '';
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _prescriptionCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final updated = await ref
        .read(appointmentActionsProvider.notifier)
        .updateStatus(_appointment.id, status);
    if (updated != null) {
      setState(() => _appointment = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Status atualizado para ${statusLabel(status)}')),
        );
        ref.invalidate(appointmentsListProvider);
      }
    }
  }

  Future<void> _saveNotes() async {
    final updated = await ref
        .read(appointmentActionsProvider.notifier)
        .updateAppointment(_appointment.id, {
      'symptoms': _symptomsCtrl.text,
      'diagnosis': _diagnosisCtrl.text,
      'prescription': _prescriptionCtrl.text,
    });
    if (updated != null) {
      setState(() {
        _appointment = updated;
        _editing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anotações salvas com sucesso')),
        );
        ref.invalidate(appointmentsListProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("dd 'de' MMMM 'de' yyyy, HH:mm", 'pt_BR');
    final color = statusColor(_appointment.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes da Consulta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ref.watch(patientByIdProvider(_appointment.patientId)).when(
                          data: (patient) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Nascimento: ${patient.formattedDateOfBirth}',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          loading: () => const Text('Carregando...'),
                          error: (_, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paciente #${_appointment.patientId}',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                typeLabel(_appointment.type),
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(_appointment.status),
                          style: GoogleFonts.dmSans(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _infoRow(Icons.calendar_today_outlined, 'Data e hora',
                      dateFmt.format(_appointment.appointmentDate)),
                  const SizedBox(height: 8),
                  _infoRow(Icons.timer_outlined, 'Duração',
                      '${_appointment.durationMinutes} minutos'),
                  if (_appointment.reason != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.notes_outlined, 'Motivo',
                        _appointment.reason!),
                  ],
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.attach_money_rounded,
                    'Valor',
                    'R\$ ${_appointment.price.toStringAsFixed(2)}  •  ${_appointment.paid ? 'Pago' : 'Pendente'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ações de status
            if (_appointment.status != 'completed' &&
                _appointment.status != 'cancelled') ...[
              Text('Atualizar status',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _StatusActions(
                currentStatus: _appointment.status,
                onUpdate: _updateStatus,
              ),
              const SizedBox(height: 20),
            ],

            // Anotações clínicas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Anotações clínicas',
                    style: Theme.of(context).textTheme.titleMedium),
                if (_editing)
                  ElevatedButton.icon(
                    onPressed: _saveNotes,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Weight and Height small squares
            Row(
              children: [
                Expanded(
                  child: _SmallClinicalField(
                    label: 'Peso',
                    controller: _weightCtrl,
                    unit: 'kg',
                    icon: Icons.monitor_weight_outlined,
                    enabled: _editing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallClinicalField(
                    label: 'Altura',
                    controller: _heightCtrl,
                    unit: 'cm',
                    icon: Icons.height_rounded,
                    enabled: _editing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ClinicalField(
              label: 'Sintomas',
              controller: _symptomsCtrl,
              icon: Icons.sick_outlined,
              enabled: _editing,
            ),
            const SizedBox(height: 10),
            _ClinicalField(
              label: 'Diagnóstico',
              controller: _diagnosisCtrl,
              icon: Icons.medical_information_outlined,
              enabled: _editing,
            ),
            const SizedBox(height: 10),
            _ClinicalField(
              label: 'Prescrição',
              controller: _prescriptionCtrl,
              icon: Icons.medication_outlined,
              enabled: _editing,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusActions extends StatelessWidget {
  final String currentStatus;
  final Future<void> Function(String) onUpdate;

  const _StatusActions(
      {required this.currentStatus, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final actions = <({String status, String label, Color color, IconData icon})>[];

    if (currentStatus == 'pending') {
      actions.addAll([
        (
          status: 'confirmed',
          label: 'Confirmar',
          color: AppColors.confirmed,
          icon: Icons.check_circle_outline_rounded
        ),
        (
          status: 'cancelled',
          label: 'Cancelar',
          color: AppColors.cancelled,
          icon: Icons.cancel_outlined
        ),
      ]);
    } else if (currentStatus == 'confirmed') {
      actions.addAll([
        (
          status: 'in_progress',
          label: 'Iniciar',
          color: AppColors.inProgress,
          icon: Icons.play_circle_outline_rounded
        ),
        (
          status: 'no_show',
          label: 'Não compareceu',
          color: AppColors.textHint,
          icon: Icons.person_off_outlined
        ),
      ]);
    } else if (currentStatus == 'in_progress') {
      actions.add((
        status: 'completed',
        label: 'Concluir',
        color: AppColors.completed,
        icon: Icons.done_all_rounded
      ));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) {
        return OutlinedButton.icon(
          onPressed: () => onUpdate(a.status),
          icon: Icon(a.icon, size: 16, color: a.color),
          label: Text(a.label,
              style: GoogleFonts.dmSans(color: a.color, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: a.color.withOpacity(0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }).toList(),
    );
  }
}

class _ClinicalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;

  const _ClinicalField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 3,
            style: GoogleFonts.dmSans(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              hintText:
                  enabled ? 'Toque para editar...' : 'Nenhuma informação',
              hintStyle:
                  GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 13),
              filled: false,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallClinicalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final IconData icon;
  final bool enabled;

  const _SmallClinicalField({
    required this.label,
    required this.controller,
    required this.unit,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '--',
                  ),
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
