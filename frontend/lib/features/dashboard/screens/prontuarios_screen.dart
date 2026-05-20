import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../client/providers/patient_provider.dart';
import '../../../shared/models/patient_model.dart';

class ProntuariosScreen extends ConsumerStatefulWidget {
  const ProntuariosScreen({super.key});

  @override
  ConsumerState<ProntuariosScreen> createState() => _ProntuariosScreenState();
}

class _ProntuariosScreenState extends ConsumerState<ProntuariosScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedPatientId; // Start with no patient selected
  String _searchQuery = '';
  late TextEditingController _searchController;
  
  late TextEditingController _heartRateController;
  late TextEditingController _bloodPressureController;
  late TextEditingController _glucoseController;
  
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicConditionsController;
  late TextEditingController _medicationsController;
  
  bool _isSaving = false;

  // Colors from Dashboard
  static const Color _bg = Color(0xFFF7F9FB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceLow = Color(0xFFF2F4F6);
  static const Color _surfaceHigh = Color(0xFFE6E8EA);
  static const Color _onSurface = Color(0xFF191C1E);
  static const Color _onSurfaceVariant = Color(0xFF434654);
  static const Color _outline = Color(0xFF737685);
  static const Color _outlineVariant = Color(0xFFC3C6D6);
  static const Color _primary = Color(0xFF003D9B);
  static const Color _primaryContainer = Color(0xFF0052CC);
  static const Color _primaryFixed = Color(0xFFDAE2FF);
  static const Color _secondaryFixed = Color(0xFF86F8C8);
  static const Color _onSecondaryFixed = Color(0xFF007352);
  static const Color _tertiaryFixed = Color(0xFFFFDBCF);
  static const Color _tertiary = Color(0xFF7B2600);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _heartRateController = TextEditingController();
    _bloodPressureController = TextEditingController();
    _glucoseController = TextEditingController();
    _bloodTypeController = TextEditingController();
    _allergiesController = TextEditingController();
    _chronicConditionsController = TextEditingController();
    _medicationsController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heartRateController.dispose();
    _bloodPressureController.dispose();
    _glucoseController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _saveProntuario(int patientId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await ref.read(patientRepositoryProvider).updateProfile(patientId, {
          'heart_rate': _heartRateController.text,
          'blood_pressure': _bloodPressureController.text,
          'glucose': _glucoseController.text,
          'blood_type': _bloodTypeController.text,
          'allergies': _allergiesController.text,
          'chronic_conditions': _chronicConditionsController.text,
          'medications': _medicationsController.text,
        });
        
        ref.invalidate(patientDetailsProvider(patientId));
        ref.invalidate(patientProfileProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prontuário atualizado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar prontuário: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: _selectedPatientId == null
          ? _buildPatientsList(patientsAsync)
          : _buildPatientDetails(_selectedPatientId!),
    );
  }

  Widget _buildPatientsList(AsyncValue<List<PatientModel>> patientsAsync) {
    return patientsAsync.when(
      data: (patients) {
        final filteredPatients = patients.where((p) {
          final query = _searchQuery.toLowerCase();
          return p.name.toLowerCase().contains(query) ||
              p.phone.contains(query) ||
              (p.cpf != null && p.cpf!.contains(query)) ||
              p.id.toString() == query;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pacientes e Prontuários',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              Expanded(
                child: filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum paciente encontrado.',
                          style: GoogleFonts.inter(color: _onSurfaceVariant),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro ao carregar pacientes: $err')),
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar paciente por nome, telefone, CPF ou ID...',
        prefixIcon: const Icon(Icons.search, color: _outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: _surface,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Card(
      color: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _primaryFixed,
                  child: Text(
                    patient.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: _primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: _onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${patient.id}',
                        style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Telefone: ${patient.phone}',
              style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
            ),
            if (patient.cpf != null)
              Text(
                'CPF: ${patient.cpf}',
                style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPatientId = patient.id;
                    _heartRateController.clear();
                    _bloodPressureController.clear();
                    _glucoseController.clear();
                    _bloodTypeController.clear();
                    _allergiesController.clear();
                    _chronicConditionsController.clear();
                    _medicationsController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver Prontuário'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetails(int patientId) {
    final patientAsync = ref.watch(patientDetailsProvider(patientId));

    return patientAsync.when(
      data: (patient) {
        if (_heartRateController.text.isEmpty && patient.heartRate != null) {
          _heartRateController.text = patient.heartRate!;
        }
        if (_bloodPressureController.text.isEmpty && patient.bloodPressure != null) {
          _bloodPressureController.text = patient.bloodPressure!;
        }
        if (_glucoseController.text.isEmpty && patient.glucose != null) {
          _glucoseController.text = patient.glucose!;
        }
        if (_bloodTypeController.text.isEmpty && patient.bloodType != null) {
          _bloodTypeController.text = patient.bloodType!;
        }
        if (_allergiesController.text.isEmpty && patient.allergies != null) {
          _allergiesController.text = patient.allergies!;
        }
        if (_chronicConditionsController.text.isEmpty && patient.chronicConditions != null) {
          _chronicConditionsController.text = patient.chronicConditions!;
        }
        if (_medicationsController.text.isEmpty && patient.medications != null) {
          _medicationsController.text = patient.medications!;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedPatientId = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHeader(patient)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildPatientInfoGrid(patient),
                const SizedBox(height: 32),
                _buildVitalSignsSection(patient),
                const SizedBox(height: 32),
                _buildHealthInfoSection(patient),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Erro ao carregar prontuário: $err',
          style: GoogleFonts.manrope(color: _tertiary),
        ),
      ),
    );
  }

  Widget _buildHeader(PatientModel patient) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prontuário Médico',
              style: GoogleFonts.manrope(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paciente: ${patient.name}',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                context.push('/patients/${patient.id}/history');
              },
              icon: const Icon(Icons.history_edu_rounded, size: 18),
              label: Text(
                'Prescrições e Exames',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _secondaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ativo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _onSecondaryFixed,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientInfoGrid(PatientModel patient) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Pessoais',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            children: [
              _buildInfoItem('E-mail', patient.email ?? '-'),
              _buildInfoItem('Telefone', patient.phone),
              _buildInfoItem('Data de Nascimento', patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : '-'),
              _buildInfoItem('CPF', patient.cpf ?? '-'),
              _buildInfoItem('RG', patient.rg ?? '-'),
              _buildInfoItem('Convênio', patient.insurance ?? 'Particular'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: _onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalSignsSection(PatientModel patient) {
    final isMissingData = patient.heartRate == null || patient.bloodPressure == null || patient.glucose == null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sinais Vitais',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _onSurface,
                ),
              ),
              if (isMissingData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tertiaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Dados Faltando',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _tertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVitalInputField(
                  controller: _heartRateController,
                  label: 'Freq. Cardíaca (bpm)',
                  hint: 'Ex: 80',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVitalInputField(
                  controller: _bloodPressureController,
                  label: 'Pressão Arterial',
                  hint: 'Ex: 120/80',
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVitalInputField(
                  controller: _glucoseController,
                  label: 'Glicose (mg/dL)',
                  hint: 'Ex: 90',
                  icon: Icons.opacity,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _saveProntuario(patient.id),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Salvar Prontuário'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: _surfaceLow,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildHealthInfoSection(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de Saúde',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthInputField(controller: _bloodTypeController, label: 'Tipo Sanguíneo', hint: 'Ex: A+'),
          const SizedBox(height: 16),
          _buildHealthInputField(controller: _allergiesController, label: 'Alergias', hint: 'Ex: Penicilina'),
          const SizedBox(height: 16),
          _buildHealthInputField(controller: _chronicConditionsController, label: 'Condições Crônicas', hint: 'Ex: Hipertensão'),
          const SizedBox(height: 16),
          _buildHealthInputField(controller: _medicationsController, label: 'Medicamentos em Uso', hint: 'Ex: Losartana'),
        ],
      ),
    );
  }

  Widget _buildHealthInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: _surfaceLow,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildHealthInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: _onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
