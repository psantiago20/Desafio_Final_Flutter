import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../features/home/providers/medicos_provider.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/medico_model.dart';
import '../../../shared/models/dashboard_stats_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  String _cleanError(Object err) {
    if (err is ApiException) return err.message;
    final s = err.toString();
    final match = RegExp(r'ApiException\(\d+\):\s*(.+)').firstMatch(s);
    if (match != null) return match.group(1)!;
    return 'Não foi possível carregar os dados. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final medicosAsync = ref.watch(medicosProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (kIsWeb) {
      return _buildWebLayout(
        context,
        ref,
        statsAsync,
        upcomingAsync,
        medicosAsync,
        user,
      );
    }
    return _buildMobileLayout(
      context,
      ref,
      statsAsync,
      upcomingAsync,
      medicosAsync,
      user,
    );
  }

  Widget _buildWebLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DashboardStats> statsAsync,
    AsyncValue<List<AppointmentModel>> upcomingAsync,
    AsyncValue<List<MedicoModel>> medicosAsync,
    UserModel? user,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color primaryColor = colorScheme.primary;
    final Color primaryContainer = colorScheme.primaryContainer;

    // Same color constants as DoctorSidebar / DashboardScreen
    const bg = Color(0xFFF7F9FB);
    const primary = Color(0xFF003D9B);
    const primaryFixed = Color(0xFFDAE2FF);
    const secondaryFixed = Color(0xFF86F8C8);
    const onSecondaryFixed = Color(0xFF007352);
    const tertiaryFixed = Color(0xFFFFDBCF);
    const tertiary = Color(0xFF7B2600);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1200 ? 48.0 : 24.0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(upcomingAppointmentsProvider);
              return Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 40,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
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
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    statsAsync.when(
                      data: (stats) => GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        children: [
                          _buildDoctorStatCard(
                            title: 'Consultas',
                            value: stats.pendingAppointments.toString(),
                            icon: Icons.calendar_today,
                            iconColor: primary,
                            circleColor: primaryFixed,
                          ),
                          _buildDoctorStatCard(
                            title: 'Realizadas',
                            value: stats.completedAppointments.toString(),
                            icon: Icons.check_circle,
                            iconColor: onSecondaryFixed,
                            circleColor: secondaryFixed,
                          ),
                          _buildDoctorStatCard(
                            title: 'Canceladas',
                            value: stats.cancelledAppointments.toString(),
                            icon: Icons.cancel_outlined,
                            iconColor: tertiary,
                            circleColor: tertiaryFixed,
                          ),
                          _buildDoctorStatCard(
                            title: 'Mensagens',
                            value: stats.unreadMessages.toString(),
                            icon: Icons.chat_bubble_outline,
                            iconColor: primary,
                            circleColor: primaryFixed,
                            badge: stats.unreadMessages > 0,
                          ),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          _buildInlineError(_cleanError(err)),
                    ),
                    const SizedBox(height: 48),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              upcomingAsync.when(
                                data: (appointments) =>
                                    _buildWebTimeline(context, appointments),
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (err, stack) =>
                                    _buildInlineError(_cleanError(err)),
                              ),
                              const SizedBox(height: 32),
                              statsAsync.when(
                                data: (stats) => _buildWebHealthSection(stats),
                                loading: () => const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (err, stack) =>
                                    _buildWebHealthSection(null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            children: [
                              statsAsync.when(
                                data: (stats) => _buildWebVitalsCard(stats),
                                loading: () => const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (err, stack) =>
                                    _buildVitalsUnavailable(),
                              ),
                              const SizedBox(height: 32),
                              _buildWebSideNavLink(
                                Icons.history,
                                'Histórico Médico',
                              ),
                              _buildWebSideNavLink(
                                Icons.headset_mic_outlined,
                                'Suporte ao Paciente',
                              ),
                              _buildWebSideNavLink(
                                Icons.folder_shared_outlined,
                                'Documentos Legais',
                              ),
                              const SizedBox(height: 32),
                              _buildWebComplianceBadge(context),
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
          ),
            );
        },
      ),
    );
  }

  // Doctor-style stat card: circle icon top-left, decorative circle bg,
  // large number, uppercase label — identical design to DashboardScreen.
  Widget _buildDoctorStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color circleColor,
    bool badge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle bleeding off top-right corner
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: circleColor.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      if (badge)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                // Value
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTimeline(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline de Atendimento',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: const Text(
                  'Ver tudo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
                  DateFormat(
                    'dd MMM, HH:mm',
                    'pt_BR',
                  ).format(apt.appointmentDate),
                  'Unidade Principal',
                  apt.type == 'consulta'
                      ? const Color(0xFF003D9B)
                      : const Color(0xFF006C4D),
                  'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2070&auto=format&fit=crop',
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWebTimelineItem(
    String name,
    String spec,
    String time,
    String loc,
    Color borderColor,
    String imgUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(imgUrl)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  spec,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
              Text(
                loc,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebHealthSection(DashboardStats? stats) {
    return Row(
      children: [
        Expanded(
          child: _buildWebHealthCard(
            'Exames de Sangue',
            Icons.analytics_outlined,
            stats?.lastExamDate,
            const Color(0xFF006C4D),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildWebHealthCard(
            'Receitas Ativas',
            Icons.medication_outlined,
            stats?.lastPrescriptionDate,
            const Color(0xFF003D9B),
          ),
        ),
      ],
    );
  }

  Widget _buildWebHealthCard(
    String title,
    IconData icon,
    String? subtitle,
    Color color,
  ) {
    final bool hasData = subtitle != null && subtitle.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4),
          Text(
            hasData
                ? 'Última atualização: $subtitle'
                : 'Sem registros recentes',
            style: TextStyle(
              color: hasData
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
              fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(40, color.withValues(alpha: 0.2)),
                      const SizedBox(width: 8),
                      _buildBar(30, color.withValues(alpha: 0.2)),
                      const SizedBox(width: 8),
                      _buildBar(70, color),
                      const SizedBox(width: 8),
                      _buildBar(35, color.withValues(alpha: 0.2)),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: color.withValues(alpha: 0.3),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum dado encontrado',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildWebVitalsCard(DashboardStats? stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SINAIS VITAIS RECENTES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildVitalItem(
            'Frequência Cardíaca',
            stats?.heartRate,
            'BPM',
            Icons.favorite,
          ),
          const SizedBox(height: 24),
          _buildVitalItem(
            'Pressão Arterial',
            stats?.bloodPressure,
            'mmHg',
            Icons.speed,
          ),
          const SizedBox(height: 24),
          _buildVitalItem(
            'Glicemia',
            stats?.glucose,
            'mg/dL',
            Icons.water_drop,
          ),
          const SizedBox(height: 24),
          _buildVitalItem(
            'Temperatura',
            stats?.temperature,
            '°C',
            Icons.thermostat,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(
    String label,
    String? value,
    String unit,
    IconData icon,
  ) {
    final bool hasValue = value != null && value.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasValue ? value : '--',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: hasValue
                        ? const Color(0xFF006C4D)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  hasValue ? unit : 'Não disponível',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasValue
                        ? const Color(0xFF006C4D)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        Icon(
          icon,
          color: const Color(0xFF006C4D).withValues(alpha: hasValue ? 0.4 : 0.15),
        ),
      ],
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SINAIS VITAIS RECENTES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Informações indisponíveis no momento.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'Estamos resolvendo isso. Tente novamente em breve.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
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
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF003D9B)),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWebComplianceBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF064E3B).withOpacity(0.6)  // green-900 opaco no dark
        : const Color(0xFF86F8C8).withOpacity(0.3);  // verde mint claro no light
    final borderColor = isDark
        ? const Color(0xFF10B981).withOpacity(0.4)
        : const Color(0xFF006C4D).withOpacity(0.1);
    final iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF007352);
    final textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF006C4D);
    final subColor = isDark ? const Color(0xFF6EE7B7).withOpacity(0.8) : const Color(0xFF006C4D);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: iconColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portal 100% Seguro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'Em conformidade com a LGPD',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
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
        decoration: BoxDecoration(gradient: AppTheme.getBackgroundGradient(context)),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(upcomingAppointmentsProvider);
            return Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                      context,
                      title: 'Próximas consultas',
                      value: stats.pendingAppointments.toString(),
                      icon: Icons.calendar_today,
                      iconColor: AppTheme.primaryBlue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Exames prontos',
                      value: stats.completedAppointments.toString(),
                      icon: Icons.description_outlined,
                      iconColor: AppTheme.successGreen,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildInlineError(_cleanError(err)),
              ),
              const SizedBox(height: 24),

              Text(
                'Próxima Consulta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('MMM', 'pt_BR')
                                          .format(nextApt.appointmentDate)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd',
                                      ).format(nextApt.appointmentDate),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${nextApt.type} - Unidade Principal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextApt.doctorName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              onPressed: () => widget.onNavigate(1),
                              style: TextButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                foregroundColor: AppTheme.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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

              Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                    context,
                    title: 'Agendar',
                    icon: Icons.calendar_today,
                    color: AppTheme.primaryBlue,
                    lightColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    onTap: () => widget.onNavigate(1),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Resultados',
                    icon: Icons.description_outlined,
                    color: AppTheme.successGreen,
                    lightColor: AppTheme.successGreenLight,
                    onTap: () => widget.onNavigate(2),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Mensagens',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF9333EA),
                    lightColor: const Color(0xFFF3E8FF),
                    onTap: () => widget.onNavigate(2),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Exames',
                    icon: Icons.description_outlined,
                    color: AppTheme.successGreen,
                    lightColor: AppTheme.successGreenLight,
                    onTap: () => widget.onNavigate(3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  Widget _buildStatCard(
    BuildContext context, {
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
