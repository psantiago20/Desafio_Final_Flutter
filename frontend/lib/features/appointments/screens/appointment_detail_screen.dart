import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:printing/printing.dart';
import '../providers/appointments_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/models/appointment_model.dart';
import 'package:frontend/features/patients/providers/patients_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_provider.dart';
import 'package:frontend/features/dashboard/widgets/doctor_sidebar.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/patients/screens/patient_history_screen.dart';

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
  final _bpmCtrl = TextEditingController();
  final _pressureCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _symptomsCtrl.text = _appointment.symptoms ?? '';
    _diagnosisCtrl.text = _appointment.diagnosis ?? '';
    // If prescription was already sent (has HTML), don't load the draft text back into the box
    _prescriptionCtrl.text = (_appointment.prescriptionHtml != null) ? '' : (_appointment.prescription ?? '');
    _weightCtrl.text = _appointment.weight ?? ''; 
    _heightCtrl.text = _appointment.height ?? '';
    _bpmCtrl.text = _appointment.heartRate ?? '';
    _pressureCtrl.text = _appointment.bloodPressure ?? '';
    _glucoseCtrl.text = _appointment.glucose ?? '';
    _tempCtrl.text = _appointment.temperature ?? '';
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _prescriptionCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bpmCtrl.dispose();
    _pressureCtrl.dispose();
    _glucoseCtrl.dispose();
    _tempCtrl.dispose();
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
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(todayAppointmentsProvider);
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
      'weight': _weightCtrl.text,
      'height': _heightCtrl.text,
      'heart_rate': _bpmCtrl.text,
      'blood_pressure': _pressureCtrl.text,
      'glucose': _glucoseCtrl.text,
      'temperature': _tempCtrl.text,
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
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(todayAppointmentsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("dd 'de' MMMM 'de' yyyy, HH:mm", 'pt_BR');
    final color = statusColor(_appointment.status);

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) const DoctorSidebar(selectedIndex: 1), // Select Agenda/Appointments
          Expanded(
            child: Column(
              children: [
                AppBar(
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
                Expanded(
                  child: SingleChildScrollView(
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
                                      color: AppColors.primary.withValues(alpha: 0.1),
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
                                      color: color.withValues(alpha: 0.12),
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
                        Text('Atualizar status',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        _StatusActions(
                          currentStatus: _appointment.status,
                          onUpdate: _updateStatus,
                        ),
                        const SizedBox(height: 24),

                        // Ferramentas
                        Text('Ferramentas',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        _ToolActions(
                          patientId: _appointment.patientId,
                        ),
                        const SizedBox(height: 24),

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
                        Row(
                          children: [
                            Expanded(
                              child: _SmallClinicalField(
                                label: 'Freq. Cardíaca',
                                controller: _bpmCtrl,
                                unit: 'BPM',
                                icon: Icons.favorite_border_rounded,
                                enabled: _editing,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SmallClinicalField(
                                label: 'Pressão Arterial',
                                controller: _pressureCtrl,
                                unit: 'mmHg',
                                icon: Icons.speed_rounded,
                                enabled: _editing,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SmallClinicalField(
                                label: 'Glicemia',
                                controller: _glucoseCtrl,
                                unit: 'mg/dL',
                                icon: Icons.water_drop_outlined,
                                enabled: _editing,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SmallClinicalField(
                                label: 'Temperatura',
                                controller: _tempCtrl,
                                unit: '°C',
                                icon: Icons.thermostat_outlined,
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
                        _PrescriptionField(
                          appointment: _appointment,
                          controller: _prescriptionCtrl,
                          onSent: (updated) {
                            if (updated != null) {
                              setState(() => _appointment = updated);
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  const _StatusActions({
    required this.currentStatus,
    required this.onUpdate,
  });

  static const _options = [
    (status: 'pending', label: 'Pendente'),
    (status: 'confirmed', label: 'Confirmado'),
    (status: 'in_progress', label: 'Em Andamento'),
    (status: 'completed', label: 'Concluído'),
    (status: 'cancelled', label: 'Cancelado'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((opt) {
        final isSelected = currentStatus == opt.status;
        return GestureDetector(
          onTap: () => onUpdate(opt.status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              opt.label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToolActions extends StatelessWidget {
  final int patientId;

  const _ToolActions({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GestureDetector(
          onTap: () {
            context.push('/patients/$patientId/history');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Text(
              'Exames e Histórico',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
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

class _PrescriptionField extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final TextEditingController controller;
  final Function(AppointmentModel?) onSent;

  const _PrescriptionField({
    super.key,
    required this.appointment,
    required this.controller,
    required this.onSent,
  });

  @override
  ConsumerState<_PrescriptionField> createState() => _PrescriptionFieldState();
}

class _PrescriptionFieldState extends ConsumerState<_PrescriptionField> {
  bool _showEditor = false;
  bool _isDownloadingPdf = false;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final hasPrescription = appointment.prescriptionHtml != null && appointment.prescriptionHtml!.isNotEmpty;
    final isLoading = ref.watch(appointmentActionsProvider).isLoading;

    if (hasPrescription && !_showEditor) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Receita Enviada ao Paciente',
                    style: GoogleFonts.dmSans(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_isDownloadingPdf)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Visualizar / Imprimir PDF',
                      onPressed: () async {
                        setState(() => _isDownloadingPdf = true);
                        try {
                          final bytes = await ref
                              .read(appointmentsRepositoryProvider)
                              .downloadPrescriptionPdf(appointment.id);
                          await Printing.layoutPdf(
                            onLayout: (format) => Uint8List.fromList(bytes),
                            name: 'Receita_Consulta_${appointment.id}.pdf',
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao carregar PDF: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isDownloadingPdf = false);
                        }
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 250),
              width: double.infinity,
              child: SingleChildScrollView(
                child: HtmlWidget(
                  appointment.prescriptionHtml!,
                  textStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        widget.controller.text = '';
                        _showEditor = true;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Enviar Nova Receita'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.medication_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  hasPrescription ? 'Nova Prescrição' : 'Prescrição',
                  style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.controller.text =
                          "Receituário:\n\n"
                          "1. [Nome do Medicamento] ----------- [Dosagem]\n"
                          "   Tomar: [Frequência e Duração]\n\n"
                          "2. [Nome do Medicamento] ----------- [Dosagem]\n"
                          "   Tomar: [Frequência e Duração]\n\n"
                          "Orientações:\n"
                          "- [Orientações adicionais ao paciente]";
                    });
                  },
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text('Usar Modelo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasPrescription) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showEditor = false;
                      });
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (widget.controller.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, digite o conteúdo da prescrição.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final notifier = ref.read(appointmentActionsProvider.notifier);

                          // 1. Save current prescription text to DB
                          await notifier.updateAppointment(appointment.id, {
                            'prescription': widget.controller.text,
                          });

                          // 2. Trigger the send (PDF generation/WhatsApp)
                          final updated = await notifier.sendPrescription(appointment.id);

                          // 3. Invalidate history to ensure archived shows up if they navigate there
                          ref.invalidate(archivedPrescriptionsProvider(appointment.patientId));
                          ref.invalidate(appointmentsListProvider);

                          if (updated != null) {
                            // Get patient name for the snackbar
                            final patient = ref.read(patientByIdProvider(appointment.patientId)).value;
                            final name = patient?.name ?? "Paciente";

                            widget.controller.clear(); // Use clear() for safety
                            widget.onSent(updated);
                            setState(() {
                              _showEditor = false;
                            });

                            // Forçar atualização de todos os providers relacionados
                            ref.invalidate(appointmentsListProvider);
                            ref.invalidate(archivedPrescriptionsProvider(appointment.patientId));

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Prescrição enviada com sucesso para $name!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.send_rounded, size: 14),
                  label: Text(isLoading ? 'Enviando...' : 'Enviar ao Paciente'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          TextField(
            controller: widget.controller,
            maxLines: 5,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              hintText: 'Digite a prescrição aqui...',
              hintStyle: GoogleFonts.dmSans(color: AppColors.textHint, fontSize: 13),
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
