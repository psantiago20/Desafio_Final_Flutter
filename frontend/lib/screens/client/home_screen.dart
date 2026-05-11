import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/home/providers/medicos_provider.dart';
import '../../shared/models/appointment_model.dart';
import '../../shared/models/medico_model.dart';
import '../../shared/models/dashboard_stats_model.dart';
import '../../shared/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/network/api_client.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  /// Extrai a mensagem amigável de qualquer tipo de exceção
  String _cleanError(Object err) {
    if (err is ApiException) return err.message;
    final s = err.toString();
    final match = RegExp(r'ApiException\(\d+\):\s*(.+)').firstMatch(s);
    if (match != null) return match.group(1)!;
    return 'Não foi possível carregar os dados. Tente novamente.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final medicosAsync = ref.watch(medicosProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (kIsWeb) {
      return _buildWebLayout(context, statsAsync, upcomingAsync, medicosAsync, user);
    }
    return _buildMobileLayout(context, statsAsync, upcomingAsync, medicosAsync, user);
  }

  // --- WEB LAYOUT ---
  Widget _buildWebLayout(
    BuildContext context,
    AsyncValue<DashboardStats> statsAsync,
    AsyncValue<List<AppointmentModel>> upcomingAsync,
    AsyncValue<List<MedicoModel>> medicosAsync,
    UserModel? user,
  ) {
    const Color primaryColor = Color(0xFF003D9B);
    const Color primaryContainer = Color(0xFF0052CC);
    const Color surfaceColor = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1200 ? 48.0 : 24.0;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bem-vindo(a) de volta, ${user?.fullName?.split(' ')[0] ?? user?.username ?? 'Paciente'}!',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aqui está um resumo da sua saúde hoje.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Stats Grid
                    statsAsync.when(
                      data: (stats) => GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.4,
                        children: [
                          _buildWebStatCard('Próximas consultas', stats.pendingAppointments.toString(), Icons.calendar_today, primaryColor),
                          _buildWebStatCard('Consultas realizadas', stats.completedAppointments.toString(), Icons.check_circle_outline, const Color(0xFF006C4D)),
                          _buildWebStatCard('Consultas canceladas', stats.cancelledAppointments.toString(), Icons.cancel_outlined, const Color(0xFFD97706)),
                          _buildWebStatCard('Mensagens não lidas', stats.unreadMessages.toString(), Icons.chat_bubble_outline, const Color(0xFF9333EA)),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => _buildInlineError(_cleanError(err)),
                    ),
                    const SizedBox(height: 48),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Timeline & Health
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              upcomingAsync.when(
                                data: (appointments) => _buildWebTimeline(context, appointments),
                                loading: () => const CircularProgressIndicator(),
                                error: (err, stack) => _buildInlineError(_cleanError(err)),
                              ),
                              const SizedBox(height: 32),
                                statsAsync.when(
                                  data: (stats) => _buildWebHealthSection(stats),
                                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                                  error: (err, stack) => _buildWebHealthSection(null),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        // Right Column: Vitals & Navigation
                        Expanded(
                          child: Column(
                            children: [
                              statsAsync.when(
                                data: (stats) => _buildWebVitalsCard(stats),
                                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                                error: (err, stack) => _buildVitalsUnavailable(),
                              ),
                              const SizedBox(height: 32),
                              _buildWebSideNavLink(Icons.history, 'Histórico Médico'),
                              _buildWebSideNavLink(Icons.headset_mic_outlined, 'Suporte ao Paciente'),
                              _buildWebSideNavLink(Icons.folder_shared_outlined, 'Documentos Legais'),
                              const SizedBox(height: 32),
                              _buildWebComplianceBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Text(value, style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: const Color(0xFF191C1E))),
            ],
          ),
          const SizedBox(height: 24),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF434654))),
        ],
      ),
    );
  }

  Widget _buildWebTimeline(BuildContext context, List<AppointmentModel> appointments) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Timeline de Atendimento', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
              TextButton(onPressed: () => onNavigate(1), child: const Text('Ver tudo', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 24),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhuma consulta agendada.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final apt = appointments[index];
                return _buildWebTimelineItem(
                  apt.doctorName,
                  '${apt.type} • Presencial',
                  DateFormat('dd MMM, HH:mm', 'pt_BR').format(apt.appointmentDate),
                  'Unidade Principal',
                  apt.type == 'consulta' ? const Color(0xFF003D9B) : const Color(0xFF006C4D),
                  'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2070&auto=format&fit=crop',
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWebTimelineItem(String name, String spec, String time, String loc, Color borderColor, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(imgUrl)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(spec, style: const TextStyle(color: Color(0xFF434654), fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: borderColor)),
              Text(loc, style: const TextStyle(color: Color(0xFF434654), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebHealthSection(DashboardStats? stats) {
    return Row(
      children: [
        Expanded(child: _buildWebHealthCard(
          'Exames de Sangue',
          Icons.analytics_outlined,
          stats?.lastExamDate,
          const Color(0xFF006C4D),
        )),
        const SizedBox(width: 24),
        Expanded(child: _buildWebHealthCard(
          'Receitas Ativas',
          Icons.medication_outlined,
          stats?.lastPrescriptionDate,
          const Color(0xFF003D9B),
        )),
      ],
    );
  }

  Widget _buildWebHealthCard(String title, IconData icon, String? subtitle, Color color) {
    final bool hasData = subtitle != null && subtitle.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasData ? 'Última atualização: $subtitle' : 'Sem registros recentes',
            style: TextStyle(
              color: hasData ? const Color(0xFF434654) : const Color(0xFF9E9E9E),
              fontSize: 12,
              fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 80,
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(40, color.withOpacity(0.2)),
                      const SizedBox(width: 8),
                      _buildBar(30, color.withOpacity(0.2)),
                      const SizedBox(width: 8),
                      _buildBar(70, color),
                      const SizedBox(width: 8),
                      _buildBar(35, color.withOpacity(0.2)),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, color: color.withOpacity(0.3), size: 32),
                        const SizedBox(height: 8),
                        Text('Nenhum dado encontrado',
                            style: TextStyle(color: color.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: hasData ? () {} : null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(hasData ? 'Visualizar PDF' : 'Indisponível'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildWebVitalsCard(DashboardStats? stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SIGNOS VITAIS RECENTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF434654))),
          const SizedBox(height: 24),
          _buildVitalItem('Frequência Cardíaca', stats?.heartRate, 'BPM', Icons.favorite),
          const SizedBox(height: 24),
          _buildVitalItem('Pressão Arterial', stats?.bloodPressure, 'mmHg', Icons.speed),
          const SizedBox(height: 24),
          _buildVitalItem('Glicemia', stats?.glucose, 'mg/dL', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String? value, String unit, IconData icon) {
    final bool hasValue = value != null && value.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF434654))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasValue ? value! : '--',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: hasValue ? const Color(0xFF006C4D) : const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  hasValue ? unit : 'Não disponível',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValue ? const Color(0xFF006C4D) : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
        ),
        Icon(icon, color: const Color(0xFF006C4D).withOpacity(hasValue ? 0.4 : 0.15)),
      ],
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFE65100), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsUnavailable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SIGNOS VITAIS RECENTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF434654))),
          const SizedBox(height: 24),
          const Icon(Icons.cloud_off_outlined, color: Color(0xFF9E9E9E), size: 36),
          const SizedBox(height: 12),
          const Text(
            'Informações indisponíveis no momento.',
            style: TextStyle(color: Color(0xFF616161), fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estamos resolvendo isso. Tente novamente em breve.',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSideNavLink(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF003D9B)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWebComplianceBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF86F8C8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF006C4D).withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Color(0xFF007352), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portal 100% Seguro', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006C4D))),
                Text('Em conformidade com a LGPD', style: TextStyle(fontSize: 12, color: Color(0xFF006C4D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOBILE LAYOUT (Restored to original state but with real data) ---
  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<DashboardStats> statsAsync,
    AsyncValue<List<AppointmentModel>> upcomingAsync,
    AsyncValue<List<MedicoModel>> medicosAsync,
    UserModel? user,
  ) {
    return Scaffold(
      appBar: const CustomAppBar(
        subtitle: 'Sua Saúde em um só lugar',
        showProfileButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user?.fullName?.split(' ')[0] ?? user?.username ?? 'Paciente'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bem-vinda ao seu portal de saúde',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid (Real Data)
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      title: 'Próximas consultas',
                      value: stats.pendingAppointments.toString(),
                      icon: Icons.calendar_today,
                      iconColor: AppTheme.primaryBlue,
                    ),
                    _buildStatCard(
                      title: 'Exames prontos',
                      value: stats.completedAppointments.toString(), // Usando consultas concluídas como proxy ou similar disponível
                      icon: Icons.description_outlined,
                      iconColor: AppTheme.successGreen,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildInlineError(_cleanError(err)),
              ),
              const SizedBox(height: 24),

              // Next Appointment Card (Real Data)
              const Text(
                'Próxima Consulta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              upcomingAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhuma consulta agendada.'),
                      ),
                    );
                  }
                  final nextApt = appointments.first;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('MMM', 'pt_BR').format(nextApt.appointmentDate).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd').format(nextApt.appointmentDate),
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${nextApt.type} - Unidade Principal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextApt.doctorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
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
                              onPressed: () => onNavigate(1),
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildInlineError(_cleanError(err)),
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
                    onTap: () => onNavigate(2),
                  ),
                  _buildActionCard(
                    title: 'Exames',
                    icon: Icons.description_outlined,
                    color: AppTheme.successGreen,
                    lightColor: AppTheme.successGreenLight,
                    onTap: () => onNavigate(3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color iconColor}) {
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
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, required Color lightColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
