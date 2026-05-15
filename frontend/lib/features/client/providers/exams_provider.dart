import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

final examsListProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, int?>((ref, patientId) async {
  final endpoint = patientId != null 
      ? '${AppConstants.examsEndpoint}?patient_id=$patientId'
      : AppConstants.examsEndpoint;
  
  final data = await ApiClient.get(endpoint);
  final list = (data as Map<String, dynamic>)['exams'] as List;
  return list.cast<Map<String, dynamic>>();
});

final filteredExamsProvider = Provider.family.autoDispose<List<Map<String, dynamic>>, int?>((ref, patientId) {
  final examsAsync = ref.watch(examsListProvider(patientId));
  return examsAsync.maybeWhen(
    data: (allExams) => allExams.where((exam) {
        final url = exam['exam_url'] as String?;
        final title = exam['title'] as String? ?? '';
        
        if (url == null || url.trim().isEmpty || 
            url.toLowerCase() == 'none' || 
            url.toLowerCase() == 'null' || 
            url.toLowerCase() == 'undefined' ||
            url.toLowerCase().contains('todo')) {
          return false;
        }

        final lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('erro') || 
            lowerTitle.contains('falha') || 
            lowerTitle.contains('nenhum exame')) {
          return false;
        }

        return true;
      }).toList(),
    orElse: () => [],
  );
});
