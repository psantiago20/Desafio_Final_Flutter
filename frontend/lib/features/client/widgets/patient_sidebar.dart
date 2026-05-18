import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';

class PatientSidebar extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int) onNavigate;

  const PatientSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  // Exact same color palette as DoctorSidebar
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
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final unreadCount = ref.watch(chatProvider).totalUnreadCount;

    final initials = (user?.fullName?.isNotEmpty == true)
        ? user!.fullName![0].toUpperCase()
        : (user?.username?.isNotEmpty == true
            ? user!.username[0].toUpperCase()
            : 'P');

    // Header widget
    final header = Row(
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
              initials,
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
                user?.fullName ?? user?.username ?? 'Paciente',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Portal do Paciente',
                style: GoogleFonts.inter(fontSize: 12, color: _outline),
              ),
            ],
          ),
        ),
      ],
    );

    // Nav items list
    final navItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarItem(context, 0, Icons.grid_view, 'Dashboard'),
        _buildSidebarItem(context, 1, Icons.calendar_today, 'Consultas'),
        _buildSidebarItem(context, 2, Icons.chat, 'Chat',
            badgeCount: unreadCount),
        _buildSidebarItem(context, 3, Icons.description_outlined, 'Exames'),
        _buildSidebarItem(context, 4, Icons.medication_outlined, 'Prescricoes'),
        _buildSidebarItem(context, 5, Icons.notifications_none, 'Notificacoes'),
        _buildSidebarItem(context, 6, Icons.person_outline, 'Perfil'),
      ],
    );

    // Footer widget
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _surfaceLow),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => ref.read(authProvider.notifier).logout(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );

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
      // LayoutBuilder + SingleChildScrollView + ConstrainedBox pattern:
      //   - At normal heights: Column fills the available space with the
      //     footer pushed to the bottom via mainAxisAlignment.spaceBetween.
      //   - At short heights: the content scrolls rather than overflowing.
      //   No Spacer / IntrinsicHeight needed — both are problematic inside
      //   scroll views.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Top group ──────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 32),
                      navItems,
                    ],
                  ),
                  // ── Bottom group ────────────────────────────────────
                  footer,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String title, {
    int badgeCount = 0,
  }) {
    final isActive = selectedIndex == index;
    return InkWell(
      onTap: () => onNavigate(index),
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
            Icon(icon,
                color: isActive ? _onSecondaryFixed : _onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.w600,
                  color:
                      isActive ? _onSecondaryFixed : _onSurfaceVariant,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
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
