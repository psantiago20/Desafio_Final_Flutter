import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/medico_model.dart';

final medicosProvider = FutureProvider<List<MedicoModel>>((ref) async {
  final response = await ApiClient.get('/api/medicos');
  final list = response as List<dynamic>;
  return list.map((e) => MedicoModel.fromJson(e as Map<String, dynamic>)).toList();
});
