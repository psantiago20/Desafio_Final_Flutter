import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/appointments/providers/appointments_live_sync.dart';
import '../../../shared/widgets/app_logo.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'results_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  int _currentIndex = 0;

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
    const Scaffold(body: Center(child: Text('Alertas e Notificações'))),
    const ProfileScreen(), // 5: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    // Sincronização em tempo real
    ref.watch(appointmentsLiveSyncProvider);
    ref.watch(chatLiveSyncProvider);

    if (kIsWeb) {
      return _buildWebShell(context);
    }
    return _buildMobileShell(context);
  }

  Widget _buildWebShell(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryContainer = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    // Calcular iniciais
    String initials = 'SC';
    if (user != null && user.fullName != null && user.fullName!.isNotEmpty) {
      final names = user.fullName!.split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        initials = names[0][0].toUpperCase();
      }
    } else if (user != null) {
      initials = user.username.substring(0, 1).toUpperCase();
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // Global Header for Web
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _navigate(0),
                  child: Row(
                    children: [
                      const AppLogo(showText: false, iconSize: 28),
                      const SizedBox(width: 16),
                      Text(
                        'Sua Consulta',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildWebNavLink('Dashboard', isActive: _currentIndex == 0, onTap: () => _navigate(0)),
                _buildWebNavLink('Consultas', isActive: _currentIndex == 1, onTap: () => _navigate(1)),
                _buildWebNavLink('Exames', isActive: _currentIndex == 3, onTap: () => _navigate(3)),
                _buildWebNavLink('Mensagens', isActive: _currentIndex == 2, onTap: () => _navigate(2)),
                const SizedBox(width: 24),
                IconButton(icon: const Icon(Icons.notifications_none), color: onSurfaceVariant, onPressed: () => _navigate(4)),
                IconButton(icon: Icon(Icons.settings_outlined, color: _currentIndex == 5 ? primaryContainer : onSurfaceVariant), onPressed: () => _navigate(5)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  color: primaryContainer,
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNavLink(String label, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: 'Consultas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Colors.white),
            label: 'Exames',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: Colors.white),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}
