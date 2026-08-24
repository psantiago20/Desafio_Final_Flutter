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

  Future<PatientModel> getPatient(int id) async {
    try {
      final response = await ApiClient.get('/api/patients/$id');
      return PatientModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PatientModel>> listPatients() async {
    try {
      final response = await ApiClient.get('/api/patients');
      final list = response['patients'] as List;
      return list.map((json) => PatientModel.fromJson(json as Map<String, dynamic>)).toList();
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
