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
      return _buildWeb(context, ref);
    }
    return _buildMobile(context, ref);
  }

  Widget _buildWeb(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final filters = ref.watch(appointmentFiltersProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: Column(
          children: [
            // Filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip(context, ref, 'Próximas', 'confirmed', filters.statusFilter == 'confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'Realizadas', 'completed', filters.statusFilter == 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'Todas', null, filters.statusFilter == null),
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
                      return _buildAppointmentCard(context, ref, appointments[index]);
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
    final filters = ref.watch(appointmentFiltersProvider);

    return Scaffold(
      appBar: kIsWeb ? null : const CustomAppBar(
        subtitle: 'Minhas Consultas',
        showProfileButton: false,
        actions: [
          Icon(Icons.add_circle, color: AppTheme.primaryBlue, size: 32),
          SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: Column(
          children: [
            // Filtros — idêntico à versão web
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  _buildFilterChip(context, ref, 'Próximas', 'confirmed', filters.statusFilter == 'confirmed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'Realizadas', 'completed', filters.statusFilter == 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'Todas', null, filters.statusFilter == null),
                ],
              ),
            ),
            // Lista
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
                      return _buildAppointmentCard(context, ref, appointments[index]);
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String? value, bool isSelected) {
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
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, WidgetRef ref, AppointmentModel apt) {
    final isUpcoming = (apt.status == 'confirmed' || apt.status == 'pending') && apt.appointmentDate.isAfter(DateTime.now());
    final isPast = apt.appointmentDate.isBefore(DateTime.now()) || apt.status == 'completed' || apt.status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isPast ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isUpcoming ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Theme.of(context).colorScheme.outline,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM', 'pt_BR').format(apt.appointmentDate).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE0F2FE) : Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd').format(apt.appointmentDate),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE0F2FE) : Theme.of(context).colorScheme.primary,
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
                          typeLabel(apt.type).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUpcoming ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel(apt.status),
                          style: TextStyle(
                            fontSize: 10,
                            color: isUpcoming 
                                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE0F2FE) : Theme.of(context).colorScheme.primary) 
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    apt.doctorName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(apt.appointmentDate),
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Unidade Principal',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Botões de Ação
                  if (isUpcoming) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE0F2FE) : Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Ver detalhes'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancelar Consulta'),
                                content: const Text('Tem certeza que deseja cancelar esta consulta?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true), 
                                    style: TextButton.styleFrom(foregroundColor: AppTheme.alertRed),
                                    child: const Text('Sim, cancelar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              await ref.read(appointmentActionsProvider.notifier).updateStatus(apt.id, 'cancelled');
                              ref.invalidate(appointmentsListProvider);
                            }
                          },
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
