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

  // WEB SHELL: sidebar on the left, Column(topBar + pages) on the right.
  // Using Column instead of Stack+Positioned so the IndexedStack gets
  // the actual remaining height (Stack would size to its tallest
  // non-positioned child = 64px, making the pages invisible).
  Widget _buildWebShell(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.fullName ?? user?.username ?? 'Paciente';

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : _bg,
      body: Row(
        children: [
          // Persistent sidebar (desktop only)
          if (isDesktop)
            PatientSidebar(
              selectedIndex: _currentIndex,
              onNavigate: _navigate,
            ),

          // Right panel: top bar + page content stacked vertically
          Expanded(
            child: Column(
              children: [
                // Fixed-height top bar
                _buildTopBar(isDesktop, userName, isDark),
                // Pages fill the rest of the available height
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page title derived from current index
          Text(
            _pageTitle(_currentIndex),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : _primaryContainer,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: _onSurfaceVariant),
                onPressed: () => _navigate(5),
                splashRadius: 24,
              ),
              const SizedBox(width: 4),
              // Theme toggle
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
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
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

  // MOBILE SHELL: bottom nav bar, unchanged from the original.
  Widget _buildMobileShell(BuildContext context) {
    return Scaffold(
      key: MainDashboardScreen.scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigate,
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
            selectedIcon: const Icon(Icons.calendar_month, color: Colors.white),
            label: 'Consultas',
          ),
          NavigationDestination(
            icon: ref.watch(chatProvider).totalUnreadCount > 0
                ? Badge(
                    label: Text(
                        ref.watch(chatProvider).totalUnreadCount.toString()),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description, color: Colors.white),
            label: 'Exames',
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication, color: Colors.white),
            label: 'Prescricoes',
          ),
        ],
      ),
    );
  }
}
