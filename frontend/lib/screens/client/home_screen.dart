import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Portal do Paciente',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá, Maria Silva!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bem-vinda ao seu portal de saúde',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: 'Próximas consultas',
                  value: '2',
                  icon: Icons.calendar_today,
                  iconColor: AppTheme.primaryBlue,
                ),
                _buildStatCard(
                  title: 'Resultados novos',
                  value: '3',
                  icon: Icons.description_outlined,
                  iconColor: AppTheme.successGreen,
                ),
                _buildStatCard(
                  title: 'Alertas ativos',
                  value: '3',
                  icon: Icons.notifications_none,
                  iconColor: AppTheme.warningOrange,
                ),
                _buildStatCard(
                  title: 'Mensagens não lidas',
                  value: '2',
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF9333EA), // purple-600
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Next Appointment
            const Text(
              'Próxima Consulta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'MAI',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '08',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consulta - Cardiologia',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Dr. João Santos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: AppTheme.textTertiary),
                                  SizedBox(width: 4),
                                  Text(
                                    '14:30',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textTertiary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Clínica CardioSaúde',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                                  ),
                                ],
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
                        onPressed: () => onNavigate(1), // Vai para Agenda
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlueLight,
                          foregroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Ver detalhes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  title: 'Agendar',
                  icon: Icons.calendar_today,
                  color: AppTheme.primaryBlue,
                  lightColor: AppTheme.primaryBlueLight,
                  onTap: () => onNavigate(1),
                ),
                _buildActionCard(
                  title: 'Resultados',
                  icon: Icons.description_outlined,
                  color: AppTheme.successGreen,
                  lightColor: AppTheme.successGreenLight,
                  onTap: () => onNavigate(2),
                ),
                _buildActionCard(
                  title: 'Mensagens',
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF9333EA),
                  lightColor: const Color(0xFFF3E8FF),
                  onTap: () => onNavigate(2), // Vai para o Chat
                ),
                _buildActionCard(
                  title: 'Exames',
                  icon: Icons.description_outlined,
                  color: AppTheme.successGreen,
                  lightColor: AppTheme.successGreenLight,
                  onTap: () => onNavigate(3), // Vai para exames
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 24),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
