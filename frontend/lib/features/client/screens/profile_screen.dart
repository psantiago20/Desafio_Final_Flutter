import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: kIsWeb ? null : const CustomAppBar(
        subtitle: 'Meu Perfil',
        showProfileButton: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header do Perfil
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                          Text(
                            user?.fullName ?? 'Usuário',
                            style: const TextStyle(
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
                  child: TextButton(
                    onPressed: () {},
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
          const SizedBox(height: 24),

          // Informações Pessoais
          _buildSectionTitle('Informações Pessoais'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildInfoTile(Icons.mail_outline, 'E-mail', user?.email ?? '-'),
                const Divider(),
                _buildInfoTile(Icons.person_outline, 'Usuário', user?.username ?? '-'),
                const Divider(),
                _buildInfoTile(Icons.phone_outlined, 'Telefone', user?.phone ?? '-'),
                const Divider(),
                _buildInfoTile(Icons.calendar_today_outlined, 'Data de Nascimento', '15/03/1985'),
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
                  _buildInfoTile(Icons.favorite_border, 'Tipo Sanguíneo', 'O+', iconColor: AppTheme.alertRed),
                  const Divider(),
                  _buildInfoTile(Icons.description_outlined, 'Alergias', 'Penicilina, Pólen'),
                  const Divider(),
                  _buildInfoTile(Icons.medical_information_outlined, 'Condições Crônicas', 'Hipertensão'),
                  const Divider(),
                  _buildInfoTile(Icons.medication_outlined, 'Medicamentos em Uso', 'Losartana 50mg'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Estatísticas (se for paciente)
          if (user?.role == 'patient') ...[
            _buildSectionTitle('Estatísticas'),
            Row(
              children: [
                Expanded(child: _buildStatCard('12', 'Consultas', AppTheme.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('24', 'Exames', AppTheme.successGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('8', 'Médicos', const Color(0xFF9333EA))),
              ],
            ),
            const SizedBox(height: 24),
          ],

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

          // Logout
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // Logout Real
                ref.read(authProvider.notifier).logout();
                context.go('/'); // Volta para a Home (Landing Page)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sessão encerrada com sucesso.')),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair da Conta'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.alertRedLight,
                foregroundColor: AppTheme.alertRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Sua Consulta v1.0.0',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor ?? AppTheme.textTertiary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard(String value, String label, Color color) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
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
            Icon(icon, size: 24, color: AppTheme.textTertiary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
