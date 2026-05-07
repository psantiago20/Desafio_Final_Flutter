import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

/// 📅 Agenda Screen (Appointments)
/// Responsabilidade: flutter-frontend-agent
/// Interface de gerenciamento de consultas.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String _currentFilter = 'upcoming'; // upcoming, completed, all

  final List<Map<String, dynamic>> _mockAppointments = [
    {
      'id': 1,
      'type': 'consultation',
      'specialty': 'Cardiologia',
      'doctor': 'Dr. João Santos',
      'dateStr': '2026-05-08',
      'day': '08',
      'month': 'MAI',
      'time': '14:30',
      'location': 'Clínica CardioSaúde',
      'status': 'upcoming',
    },
    {
      'id': 3,
      'type': 'consultation',
      'specialty': 'Dermatologia',
      'doctor': 'Dra. Ana Costa',
      'dateStr': '2026-04-28',
      'day': '28',
      'month': 'ABR',
      'time': '10:00',
      'location': 'Clínica DermaSaúde',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = _mockAppointments.where((apt) {
      if (_currentFilter == 'all') return true;
      return apt['status'] == _currentFilter;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        subtitle: 'Minhas Consultas',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: AppTheme.primaryBlue,
            iconSize: 32,
            onPressed: () {
              // TODO: Abrir modal de nova consulta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir formulário de agendamento')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                _buildFilterChip('Próximas', 'upcoming'),
                const SizedBox(width: 8),
                _buildFilterChip('Realizadas', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Todas', 'all'),
              ],
            ),
          ),
          
          // Lista de Consultas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final apt = filteredAppointments[index];
                return _buildAppointmentCard(apt);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = value;
          });
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

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final isUpcoming = apt['status'] == 'upcoming';

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
                    apt['month'],
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    apt['day'],
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
                          apt['specialty'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                          isUpcoming ? 'Confirmada' : 'Realizada',
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
                    apt['doctor'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        apt['time'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          apt['location'],
                          style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
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
