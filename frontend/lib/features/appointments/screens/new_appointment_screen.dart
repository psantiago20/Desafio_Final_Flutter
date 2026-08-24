import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/appointments_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';

class NewAppointmentScreen extends ConsumerStatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  ConsumerState<NewAppointmentScreen> createState() =>
      _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends ConsumerState<NewAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0.00');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedType = 'consultation';
  int _duration = 30;
  bool _isLoading = false;
  String? _error;

  static const _types = [
    (value: 'consultation', label: 'Consulta'),
    (value: 'return', label: 'Retorno'),
    (value: 'exam', label: 'Exame'),
    (value: 'procedure', label: 'Procedimento'),
    (value: 'follow_up', label: 'Acompanhamento'),
  ];

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _reasonCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = int.tryParse(_patientIdCtrl.text.trim());
    if (patientId == null) {
      setState(() => _error = 'ID do paciente inválido');
      return;
    }

    final doctorId = ref.read(authProvider).user?.id;
    if (doctorId == null) {
      setState(() => _error = 'Médico não autenticado');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ref.read(appointmentsRepositoryProvider).createAppointment(
            patientId: patientId,
            doctorId: doctorId,
            date: date,
            durationMinutes: _duration,
            type: _selectedType,
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
            price: double.tryParse(_priceCtrl.text) ?? 0.0,
          );

      ref.invalidate(appointmentsListProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(todayAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta agendada com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nova Consulta'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'Paciente'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _patientIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ID do Paciente',
                  prefixIcon: Icon(Icons.person_search_outlined,
                      color: AppColors.textHint),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o ID do paciente';
                  if (int.tryParse(v) == null) return 'ID inválido';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Data e Hora'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.calendar_today_rounded,
                      label: dateFmt.format(_selectedDate),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_rounded,
                      label: _selectedTime.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Tipo de Consulta'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final selected = _selectedType == t.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        t.label,
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
                }).toList(),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Duração'),
              const SizedBox(height: 10),
              Row(
                children: [15, 30, 45, 60, 90].map((d) {
                  final selected = _duration == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _duration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${d}min',
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
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              _sectionTitle(context, 'Detalhes'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined,
                      color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded,
                      color: AppColors.textHint),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cancelled.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.cancelled.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.dmSans(
                          color: AppColors.cancelled, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Agendar Consulta'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
