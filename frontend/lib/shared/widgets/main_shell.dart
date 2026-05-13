import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/appointments')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      key: _scaffoldKey,
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.primaryBlueDark),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/suaConsulta.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sua Consulta',
                        style: TextStyle(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        user?.displayName ?? 'Bem-vindo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            )
          : null,
      drawer: MediaQuery.of(context).size.width < 600
          ? _buildDrawer(context, ref)
          : null,
      body: child,
      bottomNavigationBar: MediaQuery.of(context).size.width >= 600
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex(context),
                onTap: (i) {
                  switch (i) {
                    case 0:
                      context.go('/dashboard');
                    case 1:
                      context.go('/appointments');
                    case 2:
                      context.go('/profile');
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today_rounded),
                    label: 'Consultas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentIndex = _currentIndex(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user?.displayName ?? 'Usuário',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.displayName.isNotEmpty == true
                    ? user!.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard_outlined,
              color: currentIndex == 0
                  ? AppTheme.primaryBlue
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Dashboard',
              style: TextStyle(
                fontWeight: currentIndex == 0
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: currentIndex == 0
                    ? AppTheme.primaryBlue
                    : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_today_outlined,
              color: currentIndex == 1
                  ? AppTheme.primaryBlue
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Consultas',
              style: TextStyle(
                fontWeight: currentIndex == 1
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: currentIndex == 1
                    ? AppTheme.primaryBlue
                    : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/appointments');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person_outline_rounded,
              color: currentIndex == 2
                  ? AppTheme.primaryBlue
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Perfil',
              style: TextStyle(
                fontWeight: currentIndex == 2
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: currentIndex == 2
                    ? AppTheme.primaryBlue
                    : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.alertRed),
            title: const Text(
              'Sair',
              style: TextStyle(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
