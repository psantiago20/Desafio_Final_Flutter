import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../providers/patients_provider.dart';
import '../../../shared/models/patient_model.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.trim().isNotEmpty) {
      ref.read(patientsProvider.notifier).searchPatients(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pacientes',
          style: GoogleFonts.dmSerifDisplay(
            color: AppColors.textPrimary,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, e-mail ou telefone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(patientsProvider.notifier).clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {});
                if (val.isEmpty) {
                  ref.read(patientsProvider.notifier).clearSearch();
                }
              },
            ),
          ),

          Expanded(
            child: _searchController.text.isEmpty
                ? _RecentSearches(
                    searches: patientsState.recentSearches,
                    onTap: (query) {
                      _searchController.text = query;
                      _onSearch(query);
                      setState(() {});
                    },
                  )
                : _SearchResults(
                    isLoading: patientsState.isLoading,
                    results: patientsState.searchResults,
                    error: patientsState.error,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<String> searches;
  final Function(String) onTap;

  const _RecentSearches({required this.searches, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Pesquise seus pacientes',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Pesquisas recentes',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...searches.map((query) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.search, size: 20, color: AppColors.textHint),
              title: Text(
                query,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
              onTap: () => onTap(query),
            )),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final bool isLoading;
  final List<PatientModel> results;
  final String? error;

  const _SearchResults({
    required this.isLoading,
    required this.results,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (error != null) {
      return Center(
        child: Text(error!, style: GoogleFonts.dmSans(color: AppColors.cancelled)),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          'Nenhum paciente encontrado',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final patient = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                patient.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              patient.name,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Nascimento: ${patient.formattedDateOfBirth}',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            onTap: () {
              context.push('/patients/appointments', extra: patient);
            },
          ),
        );
      },
    );
  }
}
