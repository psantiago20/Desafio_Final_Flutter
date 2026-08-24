import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/appointments/providers/appointments_live_sync.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/patient_sidebar.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'results_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'prescriptions_screen.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentIndex = 0;

  // Colors matching Doctor dashboard palette
  static const Color _bg = Color(0xFFF7F9FB);
  static const Color _onSurface = Color(0xFF191C1E);
  static const Color _onSurfaceVariant = Color(0xFF434654);
  static const Color _surfaceLow = Color(0xFFF2F4F6);
  static const Color _primaryContainer = Color(0xFF0052CC);

  void _navigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _navigate),
    const AgendaScreen(),
    const ChatScreen(),
    const ResultsScreen(),
    const PrescriptionsScreen(),
    const Scaffold(body: Center(child: Text('Alertas e Notificacoes'))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(appointmentsLiveSyncProvider);
    ref.watch(chatLiveSyncProvider);

    if (kIsWeb) {
      return _buildWebShell(context);
    }
    return _buildMobileShell(context);
  }

  // ─── WEB SHELL ────────────────────────────────────────────────────────────
  // Desktop (>= 768px): persistent sidebar on the left.
  // Narrow web (<  768px): sidebar hidden; hamburger in top bar opens a Drawer.
  Widget _buildWebShell(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.fullName ?? user?.username ?? 'Paciente';

    return Scaffold(
      key: MainDashboardScreen.scaffoldKey,
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : _bg,
      // Drawer is used on narrow web viewports as the sidebar alternative.
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              child: PatientSidebar(
                selectedIndex: _currentIndex,
                onNavigate: (index) {
                  // Close the drawer, then navigate.
                  Navigator.of(context).pop();
                  _navigate(index);
                },
              ),
            ),
      body: Row(
        children: [
          // Persistent sidebar on desktop only
          if (isDesktop)
            PatientSidebar(
              selectedIndex: _currentIndex,
              onNavigate: _navigate,
            ),

          // Right panel: top bar + page content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDesktop, userName, isDark),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop, String name, bool isDark) {
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : _bg.withOpacity(0.9);

    return Container(
      height: 64,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F191C1E),
            blurRadius: 40,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu button — only shown when sidebar is hidden
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: _onSurfaceVariant),
              onPressed: () =>
                  MainDashboardScreen.scaffoldKey.currentState?.openDrawer(),
              splashRadius: 24,
            ),
          if (!isDesktop) const SizedBox(width: 4),

          // Page title
          Expanded(
            child: Text(
              _pageTitle(_currentIndex),
              style: GoogleFonts.manrope(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _primaryContainer,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: _onSurfaceVariant),
            onPressed: () => _navigate(5),
            splashRadius: 24,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: _onSurfaceVariant,
            ),
            onPressed: () =>
                ref.read(themeProvider.notifier).toggleTheme(),
            splashRadius: 24,
          ),
          if (isDesktop) ...[
            const SizedBox(width: 12),
            Container(height: 32, width: 1, color: _surfaceLow),
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
                    color: isDark ? Colors.white : _onSurface,
                  ),
                ),
                Text(
                  'Paciente',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFDAE2FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF003D9B),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _pageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Minhas Consultas';
      case 2:
        return 'Chat';
      case 3:
        return 'Meus Exames';
      case 4:
        return 'Prescricoes';
      case 5:
        return 'Notificacoes';
      case 6:
        return 'Meu Perfil';
      default:
        return 'Portal do Paciente';
    }
  }

  // Maps mobile bottom nav tabs → _screens index
  // 0=Início(0), 1=Consultas(1), 2=Chat(2), 3=Exames(3), 4=Perfil(6)
  // Receitas(4) is accessed via the "Mais" sheet.
  static const List<int> _mobileNavToScreen = [0, 1, 2, 3, 6];

  // ─── MOBILE SHELL ──────────────────────────────────────────────────────────
  // 5-tab bottom nav (Início, Consultas, Chat, Exames, Perfil) with a
  // floating "+" or hamburger to reach the other screens. This avoids the
  // label-wrapping issue that occurs with 6+ tabs on small screens.
  Widget _buildMobileShell(BuildContext context) {
    final mobileNavIdx = _mobileNavToScreen.indexOf(_currentIndex).clamp(0, 4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ── Custom bottom navigation bar ──────────────────────────────────────
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavItem(context, 0, mobileNavIdx, Icons.home_rounded, Icons.home_outlined, 'Início', primary, onSurface, onSurfaceVariant),
              _buildNavItem(context, 1, mobileNavIdx, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Agenda', primary, onSurface, onSurfaceVariant),
              // Central "Mais" button — opens a bottom sheet with extra pages
              Expanded(
                child: GestureDetector(
                  onTap: () => _openMoreSheet(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withBlue(255)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavItemWithBadge(context, 2, mobileNavIdx, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat', primary, onSurface, onSurfaceVariant),
              _buildNavItem(context, 4, mobileNavIdx, Icons.person_rounded, Icons.person_outline_rounded, 'Perfil', primary, onSurface, onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int navIdx,
    int currentNavIdx,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    Color primary,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    final isSelected = navIdx == currentNavIdx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigate(_mobileNavToScreen[navIdx]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? primary : onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primary : onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    BuildContext context,
    int navIdx,
    int currentNavIdx,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    Color primary,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    final isSelected = navIdx == currentNavIdx;
    final unreadCount = ref.watch(chatProvider).totalUnreadCount;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigate(_mobileNavToScreen[navIdx]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected ? primary : onSurfaceVariant,
                    size: 22,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primary : onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "Mais" bottom sheet ────────────────────────────────────────────────────
  void _openMoreSheet(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Mais opções',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Grid of options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildSheetOption(context, Icons.medication_rounded, 'Receitas', const Color(0xFF6366F1), () {
                      Navigator.pop(context);
                      _navigate(4);
                    }),
                    _buildSheetOption(context, Icons.description_rounded, 'Exames', const Color(0xFF059669), () {
                      Navigator.pop(context);
                      _navigate(3);
                    }),
                    _buildSheetOption(context, Icons.notifications_rounded, 'Alertas', const Color(0xFFF59E0B), () {
                      Navigator.pop(context);
                      _navigate(5);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(top: false, child: const SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
