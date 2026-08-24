import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/client/screens/main_dashboard_screen.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/theme_provider.dart';
import 'package:frontend/shared/widgets/main_shell.dart';
import 'package:frontend/shared/widgets/app_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showProfileButton;
  final bool showThemeButton;
  final Widget? leading;
  final bool showMenuButton;

  const CustomAppBar({
    super.key,
    required this.subtitle,
    this.actions,
    this.bottom,
    this.showProfileButton = true,
    this.showThemeButton = false,
    this.leading,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      automaticallyImplyLeading: leading == null,
      leading: leading ?? (showMenuButton ? Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            if (MainShell.scaffoldKey.currentState != null) {
              MainShell.scaffoldKey.currentState?.openDrawer();
            } else if (MainDashboardScreen.scaffoldKey.currentState !=
                null) {
              MainDashboardScreen.scaffoldKey.currentState?.openDrawer();
            } else if (DashboardScreen.scaffoldKey.currentState != null) {
              DashboardScreen.scaffoldKey.currentState?.openDrawer();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ) : null),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppLogo(showText: false, iconSize: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sua Consulta',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ...?actions,
        if (showThemeButton)
          Consumer(
            builder: (context, ref, child) {
              final isDark = ref.watch(themeProvider) == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
        if (showProfileButton)
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => context.push('/profile'),
          ),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
