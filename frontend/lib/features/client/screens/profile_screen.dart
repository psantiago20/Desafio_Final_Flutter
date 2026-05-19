import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../../../shared/models/patient_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit(PatientModel? patient, dynamic user) {
    if (!_isEditing) {
      _nameController.text = patient?.name ?? user?.fullName ?? '';
      _phoneController.text = patient?.phone ?? user?.phone ?? '';
      _emailController.text = patient?.email ?? user?.email ?? '';
      _selectedBirthDate = patient?.dateOfBirth;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile(PatientModel patient) async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(patientRepositoryProvider).updateProfile(patient.id, {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'date_of_birth': _selectedBirthDate?.toIso8601String(),
        });
        
        ref.invalidate(patientProfileProvider);
        setState(() {
          _isEditing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar perfil: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final patientAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: kIsWeb ? null : const CustomAppBar(
        subtitle: 'Meu Perfil',
        showProfileButton: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: patientAsync.when(
          data: (patient) => _buildContent(context, user, patient),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildContent(context, user, null, error: err.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user, PatientModel? patient, {String? error}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header do Perfil
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: Colors.white, fontSize: 18),
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                            )
                          else
                            Text(
                              patient?.name ?? user?.fullName ?? 'Usuário',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            user?.role == 'doctor' ? 'Médico' : 'Paciente',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (_isEditing) ...[
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _saveProfile(patient!),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ] else
                        Expanded(
                          child: TextButton(
                            onPressed: () => _toggleEdit(patient, user),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Editar Perfil'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Aviso: Algumas informações podem estar indisponíveis. ($error)',
                style: TextStyle(color: AppTheme.alertRed, fontSize: 12),
              ),
            ),

          // Informações Pessoais
          _buildSectionTitle('Informações Pessoais'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                if (_isEditing) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                  ),
                  const Divider(),
                  _buildInfoTile(Icons.person_outline, 'Usuário', user?.username ?? '-'),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                    ),
                  ),
                ] else ...[
                  _buildInfoTile(Icons.mail_outline, 'E-mail', patient?.email ?? user?.email ?? '-'),
                  const Divider(),
                  _buildInfoTile(Icons.phone_outlined, 'Telefone', patient?.phone ?? user?.phone ?? '-'),
                  const Divider(),
                  _buildInfoTile(Icons.person_outline, 'Usuário', user?.username ?? '-'),
                ],
                const Divider(),
                if (_isEditing)
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Data de Nascimento'),
                    subtitle: Text(_selectedBirthDate != null ? dateFormat.format(_selectedBirthDate!) : 'Não informada'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthDate ?? DateTime(1990),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedBirthDate = picked);
                      }
                    },
                  )
                else
                  _buildInfoTile(
                    Icons.calendar_today_outlined, 
                    'Data de Nascimento', 
                    patient?.dateOfBirth != null ? dateFormat.format(patient!.dateOfBirth!) : '-'
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Informações de Saúde
          if (user?.role == 'patient' || user?.role == 'receptionist') ...[
            _buildSectionTitle('Informações de Saúde'),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildInfoTile(Icons.favorite_border, 'Tipo Sanguíneo', patient?.bloodType ?? 'Não informado', iconColor: AppTheme.alertRed),
                  const Divider(),
                  _buildInfoTile(Icons.description_outlined, 'Alergias', patient?.allergies ?? 'Nenhuma informada'),
                  const Divider(),
                  _buildInfoTile(Icons.medical_information_outlined, 'Condições Crônicas', patient?.chronicConditions ?? 'Nenhuma informada'),
                  const Divider(),
                  _buildInfoTile(Icons.medication_outlined, 'Medicamentos em Uso', patient?.medications ?? 'Nenhum informado'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Estatísticas Removidas como solicitado

          // Configurações
          _buildSectionTitle('Configurações e Suporte'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionTile(Icons.settings_outlined, 'Configurações Gerais'),
                const Divider(),
                _buildActionTile(Icons.security_outlined, 'Privacidade e Dados'),
                const Divider(),
                _buildActionTile(Icons.help_outline, 'Central de Ajuda'),
                if (user?.isAdmin ?? false) ...[
                  const Divider(),
                  _buildActionTile(
                    Icons.admin_panel_settings_outlined, 
                    'Painel do Administrador',
                    onTap: () => context.push('/management-v1'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // ── Sair — só visível no app mobile (web tem o menu lateral) ──────
          if (!kIsWeb) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sair da conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.alertRed,
                  side: BorderSide(color: AppTheme.alertRed.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _confirmLogout(context),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Center(
            child: Text(
              'Sua Consulta v1.0.0',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.alertRed, size: 24),
            const SizedBox(width: 12),
            const Text('Sair da conta'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair? Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.alertRed),
            child: Text(
              'Sair',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

