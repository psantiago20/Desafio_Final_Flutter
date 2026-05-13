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
}
