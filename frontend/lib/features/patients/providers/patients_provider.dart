import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/patients_repository.dart';
import '../../../shared/models/patient_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final patientsRepositoryProvider =
    Provider<PatientsRepository>((_) => PatientsRepository());

class PatientsState {
  final List<PatientModel> searchResults;
  final List<String> recentSearches;
  final bool isLoading;
  final String? error;

  PatientsState({
    this.searchResults = const [],
    this.recentSearches = const [],
    this.isLoading = false,
    this.error,
  });

  PatientsState copyWith({
    List<PatientModel>? searchResults,
    List<String>? recentSearches,
    bool? isLoading,
    String? error,
  }) {
    return PatientsState(
      searchResults: searchResults ?? this.searchResults,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientsNotifier extends StateNotifier<PatientsState> {
  final PatientsRepository _repository;
  static const String _recentSearchesKey = 'recent_patient_searches';

  PatientsNotifier(this._repository) : super(PatientsState()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    state = state.copyWith(recentSearches: searches);
  }

  Future<void> searchPatients(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _repository.searchPatients(query);
      
      // Update recent searches
      final updatedHistory = List<String>.from(state.recentSearches);
      updatedHistory.remove(query);
      updatedHistory.insert(0, query);
      if (updatedHistory.length > 5) {
        updatedHistory.removeLast();
      }

      state = state.copyWith(
        searchResults: results,
        recentSearches: updatedHistory,
        isLoading: false,
      );

      // Save to disk
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, updatedHistory);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao buscar pacientes');
    }
  }

  void clearSearch() {
    state = state.copyWith(searchResults: [], error: null);
  }
}

final patientsProvider =
    StateNotifierProvider<PatientsNotifier, PatientsState>((ref) {
  final repository = ref.watch(patientsRepositoryProvider);
  return PatientsNotifier(repository);
});

final patientByIdProvider =
    FutureProvider.family<PatientModel, int>((ref, id) async {
  final repository = ref.watch(patientsRepositoryProvider);
  return repository.getPatientById(id);
});

// Provider for archived prescriptions from messages table
final archivedPrescriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, patientId) async {
  // Use a direct API call or repository
  final response = await ref.read(patientsRepositoryProvider).getArchivedPrescriptions(patientId);
  return response;
});
