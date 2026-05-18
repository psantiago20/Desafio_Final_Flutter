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

  // Maps mobile bottom nav index (0-5) → _screens index (0,1,2,3,4,6)
  // Index 5 (Notificações placeholder) is intentionally skipped on mobile.
  static const List<int> _mobileNavToScreen = [0, 1, 2, 3, 4, 6];

  // ─── MOBILE SHELL ──────────────────────────────────────────────────────────
  // Bottom navigation bar with 6 tabs (Home, Consultas, Chat, Exames,
  // Prescrições, Perfil). Uses a nav→screen index map to reach ProfileScreen
  // (which lives at _screens[6]) without breaking the web shell indices.
  Widget _buildMobileShell(BuildContext context) {
    // Determine which bottom-nav tab should be highlighted.
    final mobileNavIdx = _mobileNavToScreen.indexOf(_currentIndex).clamp(0, 5);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileNavIdx,
        onDestinationSelected: (navIdx) {
          _navigate(_mobileNavToScreen[navIdx]);
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: Colors.white),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon:
                const Icon(Icons.calendar_month, color: Colors.white),
            label: 'Consultas',
          ),
          NavigationDestination(
            icon: ref.watch(chatProvider).totalUnreadCount > 0
                ? Badge(
                    label: Text(ref
                        .watch(chatProvider)
                        .totalUnreadCount
                        .toString()),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            selectedIcon:
                const Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon:
                const Icon(Icons.description, color: Colors.white),
            label: 'Exames',
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon:
                const Icon(Icons.medication, color: Colors.white),
            label: 'Prescricoes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: Colors.white),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
