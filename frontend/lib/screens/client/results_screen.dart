import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

/// 📊 Results Screen (Exams)
/// Responsabilidade: flutter-frontend-agent
/// Exibe lista de exames com status, resultados e alertas.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {

  final List<Map<String, dynamic>> _mockExams = [
    {
      'id': 1,
      'name': 'Hemograma Completo',
      'type': 'Análise Sanguínea',
      'date': 'Enviado em 01/05',
      'status': 'available',
      'doctor': 'Avaliado por Dr. João Santos',
      'hasAbnormalities': false,
    },
    {
      'id': 3,
      'name': 'Glicemia em Jejum',
      'type': 'Análise Sanguínea',
      'date': '2026-04-25',
      'status': 'available',
      'doctor': 'Dra. Maria Lima',
      'hasAbnormalities': true,
    },
    {
      'id': 4,
      'name': 'Raio-X de Tórax',
      'type': 'Imagem',
      'date': '2026-05-03',
      'status': 'pending',
      'doctor': 'Dr. Carlos Souza',
      'hasAbnormalities': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredExams = _mockExams;

    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Exames Enviados',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.primaryBlueDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Resumo da IA',
                        style: TextStyle(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Seus exames de sangue recentes estão dentro da normalidade. Não se esqueça de realizar o Raio-X de Tórax agendado.',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de Exames
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredExams.length,
              itemBuilder: (context, index) {
                return _buildExamCard(filteredExams[index]);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final bool isAvailable = exam['status'] == 'available';
    final bool isPending = exam['status'] == 'pending';
    final bool hasAbnormalities = exam['hasAbnormalities'];

    Color borderColor = AppTheme.borderGray;
    Color bgColor = AppTheme.surfaceWhite;

    if (hasAbnormalities) {
      borderColor = AppTheme.warningOrangeLight;
      bgColor = AppTheme.warningOrangeLight.withValues(alpha: 0.3);
    } else if (isAvailable) {
      borderColor = AppTheme.successGreenLight;
    }

    return Card(
      color: bgColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Block
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isAvailable ? AppTheme.successGreenLight : AppTheme.warningOrangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description,
                color: isAvailable ? AppTheme.successGreen : AppTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exam['type'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppTheme.successGreenLight : AppTheme.warningOrangeLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAvailable) ...[
                              const Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isAvailable ? 'Disponível' : 'Em análise',
                              style: TextStyle(
                                fontSize: 10,
                                color: isAvailable ? AppTheme.successGreen : AppTheme.warningOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (hasAbnormalities && isAvailable) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrangeLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppTheme.warningOrange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Atenção: Valores fora do padrão detectados',
                              style: TextStyle(fontSize: 12, color: AppTheme.warningOrange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        exam['date'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: AppTheme.textTertiary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exam['doctor'],
                          style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Actions
                  if (isAvailable) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('Visualizar'),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.backgroundGray,
                            foregroundColor: AppTheme.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppTheme.borderGray),
                            ),
                          ),
                          child: const Icon(Icons.download, size: 20),
                        ),
                      ],
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Resultado em processamento. Você será notificado quando estiver disponível.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
