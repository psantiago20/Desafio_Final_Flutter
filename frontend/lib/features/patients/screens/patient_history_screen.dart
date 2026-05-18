import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../client/providers/exams_provider.dart';
import '../providers/patients_provider.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/patient_model.dart';
import '../../client/screens/results_screen.dart';
import '../../dashboard/widgets/doctor_sidebar.dart';
import '../../../core/network/api_client.dart';

class PatientHistoryScreen extends ConsumerStatefulWidget {
  final int patientId;
  const PatientHistoryScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends ConsumerState<PatientHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _validityFilter = 'all'; // 'all', 'valid', 'invalid'

  // Colors from Dashboard
  static const Color _bg = Color(0xFFF7F9FB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF1A1C1E);
  static const Color _onSurfaceVariant = Color(0xFF44474E);
  static const Color _primary = Color(0xFF0061A4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update to show/hide validity filter
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    
    try {
      String dateStr = value.toString();
      if (dateStr.contains('Z') || dateStr.contains('+') || dateStr.contains('-')) {
        return DateTime.parse(dateStr).toLocal();
      }
      return DateTime.parse(dateStr.replaceAll(' ', 'T'));
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientByIdProvider(widget.patientId));

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          if (isDesktop) const DoctorSidebar(selectedIndex: 1),
          Expanded(
            child: patientAsync.when(
              data: (patient) => _buildContent(patient),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PatientModel patient) {
    return Column(
      children: [
        _buildHeader(patient),
        _buildTabBar(),
        if (_tabController.index == 0) _buildValidityFilter(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrescriptionsTab(),
              _buildNotesTab(),
              _buildExamsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValidityFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: _surface,
      child: Row(
        children: [
          Text('Filtro de Validade:', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 16),
          _filterButton('Todas', 'all'),
          const SizedBox(width: 8),
          _filterButton('Válidas (24h)', 'valid'),
          const SizedBox(width: 8),
          _filterButton('Inválidas', 'invalid'),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    final isSelected = _validityFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _validityFilter = value);
      },
      selectedColor: _primary.withOpacity(0.2),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? _primary : _onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildHeader(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: _surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _primary.withOpacity(0.1),
            child: Text(patient.name[0], style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: _primary)),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: _onSurface)),
              Text('CPF: ${patient.cpf ?? "Não informado"}', style: GoogleFonts.inter(color: _onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _bg,
              foregroundColor: _onSurface,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _surface,
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: _onSurfaceVariant,
        indicatorColor: _primary,
        tabs: const [
          Tab(text: 'Prescrições'),
          Tab(text: 'Anotações'),
          Tab(text: 'Exames'),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final archivedAsync = ref.watch(archivedPrescriptionsProvider(widget.patientId));

    return appointmentsAsync.when(
      data: (appointments) {
        final patientAppointments = appointments.where((a) => a.patientId == widget.patientId).toList();
        
        return archivedAsync.when(
          data: (archived) {
            final List<Map<String, dynamic>> allItems = [];
            
            for (var a in patientAppointments) {
              if (a.prescription != null && a.prescription!.trim().isNotEmpty) {
                allItems.add({'type': 'prescription', 'data': a, 'date': _parseDateTime(a.appointmentDate)});
              }
            }
            
            for (var m in archived) {
              allItems.add({'type': 'archived_prescription', 'data': m, 'date': _parseDateTime(m['created_at'])});
            }
            
            allItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

            final now = DateTime.now();
            final filteredItems = allItems.where((item) {
              if (_validityFilter == 'all') return true;
              final date = item['date'] as DateTime;
              final bool isValid = now.difference(date).inHours < 24;
              return _validityFilter == 'valid' ? isValid : !isValid;
            }).toList();

            if (filteredItems.isEmpty) return _buildEmptyState(Icons.history_edu_outlined, 'Nenhuma prescrição encontrada.');

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) => _buildHistoryCard(filteredItems[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }

  Widget _buildNotesTab() {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    return appointmentsAsync.when(
      data: (appointments) {
        final items = appointments.where((a) => a.patientId == widget.patientId && 
            ((a.notes?.isNotEmpty ?? false) || (a.diagnosis?.isNotEmpty ?? false))).toList();
        
        final List<Map<String, dynamic>> allItems = [];
        for (var a in items) {
          if (a.notes?.isNotEmpty ?? false) allItems.add({'type': 'notes', 'data': a, 'date': _parseDateTime(a.appointmentDate)});
          if (a.diagnosis?.isNotEmpty ?? false) allItems.add({'type': 'diagnosis', 'data': a, 'date': _parseDateTime(a.appointmentDate)});
        }
        
        allItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        if (allItems.isEmpty) return _buildEmptyState(Icons.notes, 'Nenhuma anotação encontrada.');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: allItems.length,
          itemBuilder: (context, index) => _buildHistoryCard(allItems[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }

  Widget _buildExamsTab() {
    return _buildEmptyState(Icons.biotech_outlined, 'Histórico de exames laboratoriais em breve.');
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: _onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final date = item['date'] as DateTime;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    
    IconData icon;
    Color color;
    String label;
    String content;
    String doctor = 'Dr. Thorne Blackwood';

    final now = DateTime.now();
    final diff = now.difference(date);
    final bool isPrescription = type == 'prescription' || type == 'archived_prescription';
    final bool isValid = diff.inHours < 24;
    final int hoursLeft = 24 - diff.inHours;
    final int minutesLeft = 60 - (diff.inMinutes % 60);

    if (item['data'] is AppointmentModel) {
      final a = item['data'] as AppointmentModel;
      doctor = a.medicoName ?? a.doctorNameFromApi ?? 'Médico';
      switch (type) {
        case 'prescription':
          icon = Icons.medication;
          color = const Color(0xFF006A6A);
          label = 'Prescrição';
          content = a.prescription!;
          break;
        case 'notes':
          icon = Icons.note_alt;
          color = Colors.orange;
          label = 'Anotações Clínicas';
          content = a.notes!;
          break;
        case 'diagnosis':
          icon = Icons.biotech;
          color = Colors.purple;
          label = 'Diagnóstico';
          content = a.diagnosis!;
          break;
        default:
          icon = Icons.history;
          color = Colors.grey;
          label = 'Registro';
          content = '';
      }
    } else {
      final m = item['data'] as Map<String, dynamic>;
      icon = Icons.history_edu_rounded;
      color = Colors.blue;
      label = 'Prescrição Enviada';
      content = m['content'] ?? '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                          _buildValidityBadge(isPrescription, isValid, hoursLeft, minutesLeft),
                        ],
                      ),
                      Text('Data: $dateStr', style: GoogleFonts.inter(color: _onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: Text(content, style: GoogleFonts.inter(fontSize: 15, color: _onSurface)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emitido por: $doctor', style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant, fontStyle: FontStyle.italic)),
                if (isPrescription) _buildDeleteButton(item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidityBadge(bool isPrescription, bool isValid, int hoursLeft, int minutesLeft) {
    if (!isPrescription) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isValid ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isValid ? Icons.check_circle : Icons.error, size: 14, color: isValid ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            isValid ? 'Válida (Expira em ${hoursLeft}h ${minutesLeft}m)' : 'Inválida (Expirada)',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isValid ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(Map<String, dynamic> item) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
      onPressed: () => _confirmDelete(item),
      tooltip: 'Excluir registro',
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro?'),
        content: const Text('Esta ação não pode ser desfeita. Deseja realmente excluir esta prescrição do histórico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (item['type'] == 'prescription') {
          final a = item['data'] as AppointmentModel;
          await ref.read(appointmentsRepositoryProvider).updateAppointment(a.id, {'prescription': ''});
          ref.invalidate(appointmentsListProvider);
        } else {
          final m = item['data'] as Map<String, dynamic>;
          await ApiClient.delete('/api/messages/${m['id']}');
          ref.invalidate(archivedPrescriptionsProvider(widget.patientId));
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro excluído com sucesso')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }
}
