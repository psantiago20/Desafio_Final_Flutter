import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../features/appointments/providers/appointments_provider.dart';
import '../../../shared/models/appointment_model.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return _buildWeb(ref);
    }
    return _buildMobile(context, ref);
  }

  Widget _buildWeb(WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final filters = ref.watch(appointmentFiltersProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip(ref, 'Próximas', 'confirmed', filters.statusFilter == 'confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(ref, 'Realizadas', 'completed', filters.statusFilter == 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(ref, 'Todas', null, filters.statusFilter == null),
                ],
              ),
            ),
            
            // Lista de Consultas
            Expanded(
              child: appointmentsAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const Center(child: Text('Nenhuma consulta encontrada.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      return _buildAppointmentCard(context, appointments[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro ao carregar consultas: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Minhas Consultas',
        actions: [
          Icon(Icons.add_circle, color: AppTheme.primaryBlue, size: 32),
          SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: appointmentsAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return const Center(child: Text('Nenhuma consulta encontrada.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final apt = appointments[index];
                final isUpcoming = apt.status == 'confirmed' || apt.status == 'pending';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: AppTheme.primaryBlueLight, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMM', 'pt_BR').format(apt.appointmentDate).toUpperCase(), 
                                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)
                              ),
                              Text(
                                DateFormat('dd').format(apt.appointmentDate), 
                                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(apt.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text(apt.doctorName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: AppTheme.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(DateFormat('HH:mm').format(apt.appointmentDate), style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isUpcoming)
                          const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro ao carregar consultas: $err')),
        ),
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, String? value, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(appointmentFiltersProvider.notifier).update(
            (state) => state.copyWith(statusFilter: value, clearStatus: value == null),
          );
        }
      },
      selectedColor: AppTheme.primaryBlue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGray,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel apt) {
    final isUpcoming = apt.status == 'confirmed' || apt.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isUpcoming ? AppTheme.primaryBlueLight : AppTheme.borderGray,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Block
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM', 'pt_BR').format(apt.appointmentDate).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd').format(apt.appointmentDate),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          apt.type.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUpcoming ? AppTheme.primaryBlueLight : AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          apt.status == 'confirmed' ? 'Confirmada' : (apt.status == 'completed' ? 'Realizada' : apt.status),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUpcoming ? AppTheme.primaryBlueDark : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    apt.doctorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(apt.appointmentDate),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textTertiary),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Unidade Principal',
                          style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Botões de Ação
                  if (isUpcoming) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlueLight,
                              foregroundColor: AppTheme.primaryBlueDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Ver detalhes'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.alertRedLight,
                            foregroundColor: AppTheme.alertRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
