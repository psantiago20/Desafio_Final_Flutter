import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_card.dart';
import 'package:frontend/shared/widgets/main_shell.dart';
import 'package:frontend/shared/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

      final validExams = list.cast<Map<String, dynamic>>().where((exam) {
        final url = exam['exam_url'] as String?;
        return url != null &&
            url.trim().isNotEmpty &&
            url.toLowerCase() != 'none' &&
            url.toLowerCase() != 'null';
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
      builder: (_) => AlertDialog(
        title: const Text('Excluir Exame'),
        content: const Text('Tem certeza que deseja remover este exame?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('${AppConstants.examsEndpoint}/$examId');
      _fetchExams();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    itemCount: _exams.length,
                    itemBuilder: (_, index) {
                      final exam = _exams[index];
                      return _buildExamCard(exam);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final date = DateTime.tryParse(exam['created_at'] ?? '');
    final formattedDate = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : '—';

    final title = exam['title'] ?? 'Exame';
    final url = exam['exam_url'] as String?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              const Icon(Icons.assignment),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _deleteExam(exam['id'] as int),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// DATA
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          /// BOTÃO DE AÇÃO
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                if (url != null && url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir exame'),
            ),
          ),
        ],
      ),
    );
  }
}
