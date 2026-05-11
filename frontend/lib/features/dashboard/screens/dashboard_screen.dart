import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/models/appointment_model.dart';
import 'package:frontend/shared/models/dashboard_stats_model.dart';
import 'package:frontend/shared/widgets/main_shell.dart';
import 'package:frontend/shared/widgets/app_card.dart';
import 'package:frontend/shared/utils/responsive_helper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final todayAsync = ref.watch(todayAppointmentsProvider);

    return MainShell(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(todayAppointmentsProvider);
        },
        child: CustomScrollView(
          slivers: [
            /// HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, Dr. ${user?.displayName.split(' ').first ?? ''}',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobileSize: 20,
                          desktopSize: 24,
                        ),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat(
                        "EEEE, d 'de' MMMM",
                        'pt_BR',
                      ).format(DateTime.now()),
                      style: GoogleFonts.dmSans(
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobileSize: 12,
                          desktopSize: 14,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: ResponsiveHelper.getResponsivePadding(context),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  /// ✅ STATS
                  statsAsync.when(
                    data: (stats) => _StatsSectionResponsive(stats: stats),
                    loading: () => const _StatsShimmer(),
                    error: (e, _) => _ErrorCard(
                      message: 'Erro ao carregar estatísticas',
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.getCardSpacing(context)),

                  /// HEADER CONSULTAS
                  ResponsiveHelper.buildResponsiveLayout(
                    context: context,
                    mobile: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultas de hoje',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/appointments'),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    desktop: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Consultas de hoje',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/appointments'),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.getCardSpacing(context)),

                  /// CONSULTAS
                  todayAsync.when(
                    data: (appointments) => appointments.isEmpty
                        ? _EmptyCard(
                            message: 'Nenhuma consulta hoje',
                            icon: Icons.event_available_rounded,
                          )
                        : Column(
                            children: appointments
                                .map((a) => _AppointmentCard(appointment: a))
                                .toList(),
                          ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => _ErrorCard(
                      message: 'Erro ao carregar consultas',
                      onRetry: () => ref.invalidate(todayAppointmentsProvider),
                    ),
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// GRID RESPONSIVO
class _StatsSectionResponsive extends StatelessWidget {
  final DashboardStats stats;

  const _StatsSectionResponsive({required this.stats});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridColumns(context);

    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final items = [
      _StatCard(
        label: 'Pacientes',
        value: '${stats.totalPatients}',
        icon: Icons.people_alt_outlined,
        color: AppColors.confirmed,
      ),
      _StatCard(
        label: 'Pendentes',
        value: '${stats.pendingAppointments}',
        icon: Icons.schedule_rounded,
        color: AppColors.pending,
      ),
      _StatCard(
        label: 'Concluídas',
        value: '${stats.completedAppointments}',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.completed,
      ),
      _StatCard(
        label: 'Receita Hoje',
        value: currencyFmt.format(stats.revenueToday),
        icon: Icons.attach_money_rounded,
        color: AppColors.primaryLight,
        smallText: true,
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: items,
    );
  }
}

/// CARD
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool smallText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.smallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(ResponsiveHelper.getCardSpacing(context) / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveHelper.getFontSize(
                context,
                mobileSize: 20,
                desktopSize: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobileSize: smallText ? 16 : 22,
                desktopSize: smallText ? 18 : 26,
              ),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// CONSULTA
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(appointment.status);
    final timeFmt = DateFormat('HH:mm');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(ResponsiveHelper.getCardSpacing(context) / 1.5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paciente #${appointment.patientId}',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
          Text(timeFmt.format(appointment.appointmentDate)),
        ],
      ),
    );
  }
}

/// SHIMMER
class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _box()),
            const SizedBox(width: 12),
            Expanded(child: _box()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _box()),
            const SizedBox(width: 12),
            Expanded(child: _box()),
          ],
        ),
      ],
    );
  }

  Widget _box() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// ERROR
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cancelled.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cancelled.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.cancelled),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

/// EMPTY
class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
