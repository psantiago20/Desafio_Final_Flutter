import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DoctorSidebar extends ConsumerWidget {
  final int selectedIndex;
  const DoctorSidebar({super.key, required this.selectedIndex});

  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF191C1E);
  static const Color _onSurfaceVariant = Color(0xFF434654);
  static const Color _outline = Color(0xFF737685);
  static const Color _primary = Color(0xFF003D9B);
  static const Color _primaryFixed = Color(0xFFDAE2FF);
  static const Color _secondaryFixed = Color(0xFF86F8C8);
  static const Color _onSecondaryFixed = Color(0xFF007352);
  static const Color _surfaceLow = Color(0xFFF2F4F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    
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
                  _buildSidebarItem(context, ref, 0, Icons.grid_view, 'Painel'),
                  _buildSidebarItem(context, ref, 1, Icons.calendar_today, 'Agenda'),
                  _buildSidebarItem(context, ref, 2, Icons.group, 'Pacientes'),
                  _buildSidebarItem(context, ref, 3, Icons.chat, 'Chat', badgeCount: statsAsync.value?.unreadMessages),
                  _buildSidebarItem(context, ref, 6, Icons.payments, 'Financeiro'),
                ],
              ),
            ),
          ),
          const Divider(color: _surfaceLow),
          const SizedBox(height: 16),
          _buildSidebarItem(context, ref, 5, Icons.settings, 'Configurações'),
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

  Widget _buildSidebarItem(BuildContext context, WidgetRef ref, int index, IconData icon, String title, {int? badgeCount}) {
    final isActive = selectedIndex == index;
    return InkWell(
      onTap: () {
        ref.read(activeDashboardTabProvider.notifier).state = index;
        final location = GoRouterState.of(context).uri.toString();
        if (!location.startsWith('/dashboard')) {
          context.go('/dashboard');
        }
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
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? _onSecondaryFixed : _onSurfaceVariant,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
