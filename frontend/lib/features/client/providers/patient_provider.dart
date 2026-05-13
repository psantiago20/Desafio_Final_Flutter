import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/patient_repository.dart';
import '../../../shared/models/patient_model.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) => PatientRepository());

final patientProfileProvider = FutureProvider<PatientModel>((ref) async {
  final repository = ref.watch(patientRepositoryProvider);
  return await repository.getMyProfile();
});
