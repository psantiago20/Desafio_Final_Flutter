import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/appointment_model.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../patients/providers/patients_provider.dart';
import '../../client/providers/patient_provider.dart';

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  String _validityFilter = 'all'; // 'all', 'valid', 'invalid'

  String _generateSimpleHtml(String content) {
    return """
    <div style="font-family: sans-serif; padding: 20px;">
      <h2 style="color: #003D9B; border-bottom: 2px solid #003D9B; padding-bottom: 10px;">Prescrição Médica</h2>
      <p style="margin-top: 20px; line-height: 1.6; white-space: pre-wrap;">$content</p>
      <div style="margin-top: 40px; border-top: 1px solid #ccc; padding-top: 20px; font-size: 12px; color: #666;">
        Gerado automaticamente pelo sistema OmniConnect
      </div>
    </div>
    """;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, 
              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma prescrição encontrada',
            style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final patientProfileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Minhas Prescricoes'), elevation: 0),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: patientProfileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (patient) {
                final archivedAsync = ref.watch(archivedPrescriptionsProvider(patient.id));

                return appointmentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erro: $err')),
                  data: (appointments) {
                    return archivedAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Erro: $err')),
                      data: (archived) {
                        final List<Map<String, dynamic>> allItems = [];

                        for (var a in appointments) {
                          if (a.prescriptionHtml != null && a.prescriptionHtml!.isNotEmpty) {
                            allItems.add({
                              'type': 'appointment',
                              'doctor': a.doctorName,
                              'date': a.appointmentDate,
                              'html': a.prescriptionHtml,
                              'id': a.id,
                            });
                          }
                        }

                        for (var m in archived) {
                          allItems.add({
                            'type': 'archive',
                            'doctor': 'Dr. Thorne Blackwood',
                            'date': DateTime.parse(m['created_at'].toString().replaceAll(' ', 'T')),
                            'html': _generateSimpleHtml(m['content']),
                            'id': m['id'],
                          });
                        }

                        allItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

                        final now = DateTime.now();
                        final filteredItems = allItems.where((item) {
                          if (_validityFilter == 'all') return true;
                          final date = item['date'] as DateTime;
                          final bool isValid = now.difference(date).inHours < 24;
                          return _validityFilter == 'valid' ? isValid : !isValid;
                        }).toList();

                        if (filteredItems.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) => _buildPrescriptionCard(filteredItems[index], now),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('Todas', 'all'),
          const SizedBox(width: 8),
          _filterChip('Válidas', 'valid'),
          const SizedBox(width: 8),
          _filterChip('Inválidas', 'invalid'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _validityFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _validityFilter = value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: GoogleFonts.dmSans(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> item, DateTime now) {
    final date = item['date'] as DateTime;
    final diff = now.difference(date);
    final bool isValid = diff.inHours < 24;
    final int hoursLeft = 24 - diff.inHours;
    final int minutesLeft = 60 - (diff.inMinutes % 60);
    
    final dateFmt = DateFormat("dd/MM/yyyy - HH:mm", 'pt_BR');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isValid ? AppColors.border : Colors.red.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isValid ? AppColors.primary : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_outlined, color: isValid ? AppColors.primary : Colors.red),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Prescrição - ${item['doctor']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16))),
            _buildBadge(isValid, hoursLeft, minutesLeft),
          ],
        ),
        subtitle: Text(dateFmt.format(date), style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => _showPrescriptionOverlay(context, item['html']),
      ),
    );
  }

  Widget _buildBadge(bool isValid, int hoursLeft, int minutesLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isValid ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isValid ? 'Válida (${hoursLeft}h)' : 'Expirada',
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: isValid ? Colors.green : Colors.red),
      ),
    );
  }

  void _showPrescriptionOverlay(BuildContext context, String html) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: HtmlWidget(html),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Fechar'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
