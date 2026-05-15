import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import 'package:frontend/features/appointments/providers/appointments_live_sync.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/appointments/providers/appointments_provider.dart';
import 'package:frontend/features/appointments/screens/appointments_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/dashboard/screens/prontuarios_screen.dart';
import 'package:frontend/features/messages/screens/doctor_messages_screen.dart';
import 'package:frontend/features/patients/screens/patients_screen.dart';
import 'package:frontend/features/dashboard/screens/financial_screen.dart';
import 'package:frontend/shared/models/appointment_model.dart';

import 'package:frontend/shared/models/dashboard_stats_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;
  String _selectedFilter = 'Todos';
  int? _selectedChatPatientId;
  String? _selectedChatPatientName;

  // Colors from HTML
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
  Widget build(BuildContext context) {
    ref.watch(appointmentsLiveSyncProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final todayAsync = ref.watch(appointmentsListProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _buildMainContent(isDesktop, user?.displayName ?? '', statsAsync, todayAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop, String name, AsyncValue<DashboardStats> statsAsync, AsyncValue<List<AppointmentModel>> todayAsync) {
    if (_selectedNavIndex == 1) {
      return const AppointmentsScreen();
    }
    if (_selectedNavIndex == 2) {
      return const ProntuariosScreen();
    }
    if (_selectedNavIndex == 3) {
      return DoctorMessagesScreen(
        initialPatientId: _selectedChatPatientId,
        initialPatientName: _selectedChatPatientName,
      );
    }
    if (_selectedNavIndex == 5) {
      return const ProfileScreen();
    }
    if (_selectedNavIndex == 6) {
      return const FinancialScreen();
    }
    if (_selectedNavIndex != 0) {

      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Página em desenvolvimento',
            style: GoogleFonts.manrope(fontSize: 24, color: _onSurfaceVariant),
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: _primary,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(todayAppointmentsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 88, // Space for Topbar
                  left: isDesktop ? 40 : 24,
                  right: isDesktop ? 40 : 24,
                  bottom: 32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(name),
                    const SizedBox(height: 32),
                    statsAsync.when(
                      data: (stats) => _buildStatsGrid(stats, isDesktop),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Erro: $e')),
                    ),
                    const SizedBox(height: 48),
                    _buildAppointmentsSection(todayAsync, isDesktop),
                  ]),
                ),
              ),
            ],
          ),
        ),
        _buildTopBar(isDesktop, name),
      ],
    );
  }

  Widget _buildTopBar(bool isDesktop, String name) {
    return Container(
      height: 64,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: _primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                'Sua Consulta',
                style: GoogleFonts.manrope(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w800,
                  color: _primaryContainer,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: _onSurfaceVariant),
                onPressed: () {},
                splashRadius: 24,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Container(
                  height: 32,
                  width: 1,
                  color: _surfaceLow,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _onSurface,
                      ),
                    ),
                    Text(
                      'Cardiologista',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: _surface,
                  backgroundImage: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBMX8qlX31tB6vkWfy_Zz-DK7twmO-VbFYtoyB5j8UDVKZ8D88EimlpADyfRtIAgT2O3fMAQKXJNaxlYXtyu9xzGF44bhGsrQPK54IjC5DDKun9ckp6-apH2R4twR__qvRKQL5EnICUTT-j8D_4TV2qjebNQTzUmdBaAHUCc805lh7ECpR2Y8fyWpXG6HQhA7fj-3EaVFo3c-bA5Q8YRjViPHJQw3cWNts03GDr77XPBIKhV1DwBmzTCWA2QvN84dviwb16MHYOFdg',
                  ),
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.logout, color: _onSurfaceVariant),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(10, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinica Alpha',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Medical Management',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v2.4.0',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarItem(0, Icons.grid_view, 'Painel'),
                  _buildSidebarItem(1, Icons.calendar_today, 'Agenda'),
                  _buildSidebarItem(2, Icons.group, 'Pacientes'),
                  _buildSidebarItem(3, Icons.chat, 'Chat'),
                  _buildSidebarItem(6, Icons.payments, 'Financeiro'),
                ],
              ),
            ),
          ),
          const Divider(color: _surfaceLow),
          const SizedBox(height: 16),
          _buildSidebarItem(5, Icons.settings, 'Configurações'),
          _buildSidebarItem(7, Icons.help_outline, 'Suporte'),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: _onSurfaceVariant),
                  const SizedBox(width: 16),
                  Text(
                    'Sair',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isActive = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedNavIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? _secondaryFixed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? _onSecondaryFixed : _onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? _onSecondaryFixed : _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    final now = DateTime.now();
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${name}.',
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(DashboardStats stats, bool isDesktop) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Pacientes',
          value: '${stats.totalPatients}',
          icon: Icons.group,
          iconColor: _primary,
          circleColor: _primaryFixed,
        ),
        _buildStatCard(
          title: 'Pendentes',
          value: '${stats.pendingAppointments}',
          icon: Icons.schedule,
          iconColor: _tertiary,
          circleColor: _tertiaryFixed,
        ),
        _buildStatCard(
          title: 'Concluídas',
          value: '${stats.completedAppointments}',
          icon: Icons.check_circle,
          iconColor: _onSecondaryFixed,
          circleColor: _secondaryFixed,
        ),
        _buildStatCard(
          title: 'Receita Hoje',
          value: currencyFmt.format(stats.revenueToday),
          icon: Icons.attach_money,
          iconColor: _onSurfaceVariant,
          circleColor: _surfaceHigh,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color circleColor,
  }) {
    return Container(
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
      child: Stack(
        children: [
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant,
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

  Widget _buildAppointmentsSection(AsyncValue<List<AppointmentModel>> todayAsync, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximas consultas',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _onSurface,
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    _buildFilterChip('Todos', _selectedFilter == 'Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pendente', _selectedFilter == 'Pendente'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmado', _selectedFilter == 'Confirmado'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Concluído', _selectedFilter == 'Concluído'),
                  ],
                ),
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', _selectedFilter == 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendente', _selectedFilter == 'Pendente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmado', _selectedFilter == 'Confirmado'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Concluído', _selectedFilter == 'Concluído'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          todayAsync.when(
            data: (appointments) {
              final sorted = List<AppointmentModel>.from(appointments)
                ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

              final filtered = sorted.where((a) {
                if (_selectedFilter == 'Todos') {
                  return a.status != 'completed' && a.status != 'cancelled';
                }
                if (_selectedFilter == 'Pendente') return a.status == 'pending';
                if (_selectedFilter == 'Confirmado') return a.status == 'confirmed';
                if (_selectedFilter == 'Concluído') return a.status == 'completed';
                return false;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Nenhuma consulta hoje',
                      style: GoogleFonts.inter(
                        color: _onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: filtered.map((a) => _buildAppointmentCard(a, isDesktop)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() => _selectedNavIndex = 1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todas',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16, color: _primaryContainer),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryContainer : _surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: _outlineVariant.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, bool isDesktop) {
    final timeFmt = DateFormat('HH:mm');
    final monthFmt = DateFormat('MMM.', 'pt_BR');
    final isCompleted = appointment.status == 'completed';
    final isPending = appointment.status == 'pending';
    
    final statusBgColor = isCompleted
        ? _secondaryFixed
        : (isPending ? _tertiaryFixed : _primaryFixed);
    final statusTextColor = isCompleted
        ? _onSecondaryFixed
        : (isPending ? _tertiary : _primary);
    final statusLabel = appointment.status == 'completed'
        ? 'Concluído'
        : (appointment.status == 'pending' ? 'Pendente' : 'Confirmado');

    return InkWell(
      onTap: () {
        context.push('/appointments/${appointment.id}', extra: appointment);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A191C1E),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCompleted ? _surfaceHigh : _primaryFixed.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${appointment.appointmentDate.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? _onSurfaceVariant : _primary,
                  ),
                ),
                Text(
                  monthFmt.format(appointment.appointmentDate).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? _onSurfaceVariant : _primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName ?? 'Paciente #${appointment.patientId}',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? _onSurface.withOpacity(0.7) : _onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: _onSurfaceVariant.withOpacity(isCompleted ? 0.7 : 1)),
                    const SizedBox(width: 4),
                    Text(
                      timeFmt.format(appointment.appointmentDate),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant.withOpacity(isCompleted ? 0.7 : 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer_outlined, size: 16, color: _onSurfaceVariant.withOpacity(isCompleted ? 0.7 : 1)),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment.durationMinutes} min',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant.withOpacity(isCompleted ? 0.7 : 1),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Consulta',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _onSurfaceVariant.withOpacity(isCompleted ? 0.7 : 1),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusTextColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: _primary),
              onPressed: () {
                setState(() {
                  _selectedNavIndex = 3;
                  _selectedChatPatientId = appointment.patientId;
                  _selectedChatPatientName = appointment.patientName;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: _onSurfaceVariant),
              onPressed: () {
                context.push('/appointments/${appointment.id}', extra: appointment);
              },
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: _primary, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedNavIndex = 3;
                          _selectedChatPatientId = appointment.patientId;
                          _selectedChatPatientName = appointment.patientName;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: _onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}

