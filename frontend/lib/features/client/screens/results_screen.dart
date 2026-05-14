import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';



/// Results Screen (Exams)
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

      // Filtra exames que não possuem URL válida ou que falharam na identificação
      final validExams = allExams.where((exam) {
        final url = exam['exam_url'] as String?;
        final title = exam['title'] as String? ?? '';
        
        // Se a URL for nula, vazia ou strings que indicam ausência de arquivo
        if (url == null || url.trim().isEmpty || 
            url.toLowerCase() == 'none' || 
            url.toLowerCase() == 'null' || 
            url.toLowerCase() == 'undefined' ||
            url.toLowerCase().contains('TODO')) {
          return false;
        }

        // Se o título indicar que falhou o upload ou é um erro
        final lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('erro') || 
            lowerTitle.contains('falha') || 
            lowerTitle.contains('nenhum exame')) {
          return false;
        }

        return true;
      }).toList();

      setState(() {
        _exams = validExams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar exames: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExam(int examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Exame'),
        content: const Text(
          'Tem certeza que deseja remover este exame? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.alertRed),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('${AppConstants.examsEndpoint}/$examId');
      _fetchExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exame removido com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao remover exame: $e')));
      }
    }
  }

  void _showFilePopup(Map<String, dynamic> exam) {
    final url = exam['exam_url'] as String?;
    final title = exam['title'] as String? ?? 'Exame';
    if (url == null) return;

    // Garantir que a URL está completa e tratar IPs de emulador legados
    String fullUrl = url;
    if (url.contains('10.0.2.2:8000')) {
      fullUrl = url.replaceAll('http://10.0.2.2:8000', AppConstants.baseUrl);
    } else if (!url.startsWith('http')) {
      final cleanUrl = url.startsWith('/') ? url : '/$url';
      fullUrl = '${AppConstants.baseUrl}$cleanUrl';
    }

    final isImage = fullUrl.toLowerCase().contains('.png') || 
                  fullUrl.toLowerCase().contains('.jpg') || 
                  fullUrl.toLowerCase().contains('.jpeg');

    int rotationTurns = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right),
                  onPressed: () => setDialogState(() => rotationTurns = (rotationTurns + 1) % 4),
                  tooltip: 'Girar 90°',
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  if (isImage)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 5.0,
                                child: Center(
                                  child: RotatedBox(
                                    quarterTurns: rotationTurns,
                                    child: Image.network(
                                      fullUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, color: AppTheme.alertRed, size: 40),
                                            SizedBox(height: 8),
                                            Text('Erro ao carregar imagem', textAlign: TextAlign.center),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Dica: Use pinça para Zoom',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.insert_drive_file, size: 80, color: AppTheme.primaryBlue),
                            SizedBox(height: 16),
                            Text(
                              'Este arquivo não pode ser visualizado diretamente.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Fechar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(fullUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Abrir/Baixar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


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
      appBar: kIsWeb ? null : const CustomAppBar(subtitle: 'Seus Resultados'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

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
      appBar: kIsWeb ? null : const CustomAppBar(subtitle: 'Seus Resultados'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  final exam = _exams[index];

                  // Formatação de data
                  DateTime? date;
                  try {
                    date = DateTime.parse(exam['created_at'] as String);
                  } catch (_) {}
                  final dateStr = date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : '—';
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
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.alertRed,
                                  size: 20,
                                ),
                                onPressed: () => _deleteExam(exam['id'] as int),
                                tooltip: 'Remover exame',
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Resultado Liberado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showFilePopup(exam),
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
    final hasFile = examUrl != null && examUrl.isNotEmpty;

    DateTime? date;
    try {
      date = DateTime.parse(exam['created_at'] as String);
    } catch (_) {}
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : '—';
    final title = exam['title'] as String? ?? 'Exame';

    return Card(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.alertRed,
                  ),
                  onPressed: () => _deleteExam(exam['id'] as int),
                  tooltip: 'Remover exame',
                ),
              ],
            ),
            if (hasFile) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showFilePopup(exam),
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
