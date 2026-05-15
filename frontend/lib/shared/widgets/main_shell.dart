import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/appointments')) return 1;
    if (location.startsWith('/patients')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final user = ref.watch(authProvider).user;
    final currentIndex = _currentIndex(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(context, ref),
      body: child,
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
                (user?.displayName != null && user!.displayName.isNotEmpty)
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
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
              Icons.people_outline_rounded,
              color: currentIndex == 2
                  ? AppTheme.primaryBlue
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Pacientes',
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
              context.go('/patients');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person_outline_rounded,
              color: currentIndex == 3
                  ? AppTheme.primaryBlue
                  : AppColors.textSecondary,
            ),
            title: Text(
              'Perfil',
              style: TextStyle(
                fontWeight: currentIndex == 3
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: currentIndex == 3
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
            },
          ),
        ],
      ),
    );
  }
}
