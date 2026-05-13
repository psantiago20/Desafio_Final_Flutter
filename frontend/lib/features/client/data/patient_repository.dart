import '../../../core/network/api_client.dart';
import '../../../shared/models/patient_model.dart';

class PatientRepository {
  Future<PatientModel> getMyProfile() async {
    try {
      final response = await ApiClient.get('/api/patients/me');
      return PatientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<PatientModel> updateProfile(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/api/patients/$id', data);
      return PatientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
