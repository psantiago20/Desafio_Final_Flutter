import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 📊 Results Screen (Exams)
/// Responsabilidade: flutter-frontend-agent
/// Exibe lista de exames com status, resultados e alertas.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get(AppConstants.examsEndpoint);
      final list = (data as Map<String, dynamic>)['exams'] as List;
      final allExams = list.cast<Map<String, dynamic>>();

      setState(() {
        _exams = allExams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar exames: $e';
        _isLoading = false;
      });
    }
  }


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
    if (kIsWeb) {
      return _buildWeb();
    }
    return _buildMobile();
  }

  Widget _buildWeb() {
    final filteredExams = _exams;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text(_error!))
            : Column(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchExams,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Seus Resultados',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  final exam = _exams[index];
                  const isAvailable = true; // No novo backend, se veio na lista, está disponível ou processando
                  
                  // Formatação de data
                  DateTime? date;
                  try {
                    date = DateTime.parse(exam['created_at'] as String);
                  } catch (_) {}
                  final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '—';
                  final title = exam['title'] as String? ?? 'Exame';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreenLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Resultado Liberado', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: Abrir URL do exame
                                },
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('Ver Resultado'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchExams,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final examUrl = exam['exam_url'] as String?;
    final summary = exam['summary'] as String?;
    final hasSummary = summary != null && summary.isNotEmpty;
    final hasFile = examUrl != null && examUrl.isNotEmpty;

    DateTime? date;
    try {
      date = DateTime.parse(exam['created_at'] as String);
    } catch (_) {}
    final dateStr =
        date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : '—';
    final title = exam['title'] as String? ?? 'Exame';

    return Card(
      color: hasSummary ? AppTheme.surfaceWhite : AppTheme.backgroundGray,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasSummary ? AppTheme.successGreen.withValues(alpha: 0.3) : AppTheme.borderGray,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasSummary ? AppTheme.successGreenLight : AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: hasSummary ? AppTheme.successGreen : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasSummary) ...[
              const SizedBox(height: 16),
              const Text(
                'Análise da IA:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (hasFile) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Abrir URL do exame
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ver Arquivo Original'),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
