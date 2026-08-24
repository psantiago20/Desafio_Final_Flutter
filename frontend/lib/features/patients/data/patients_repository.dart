import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/patient_model.dart';

class PatientsRepository {
  Future<List<PatientModel>> searchPatients(String query) async {
    final data = await ApiClient.get(
      AppConstants.patientsEndpoint,
      {'search': query},
    );
    
    // The backend returns {"total": total, "patients": patients}
    final patientsData = data['patients'] as List<dynamic>;
    
    return patientsData
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PatientModel> getPatientById(int id) async {
    final data = await ApiClient.get('${AppConstants.patientsEndpoint}/$id');
    return PatientModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getArchivedPrescriptions(int patientId) async {
    final response = await ApiClient.get('/api/messages', {'patient_id': patientId, 'limit': 100});
    final msgs = response['messages'] as List<dynamic>;
    return msgs
        .where((m) => m['meta'] == 'prescription_archive')
        .map((m) => m as Map<String, dynamic>)
        .toList();
  }
}
