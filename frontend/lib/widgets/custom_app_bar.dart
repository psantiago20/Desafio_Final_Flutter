import 'package:flutter/material.dart';
import '../screens/client/profile_screen.dart';
import '../core/theme/app_theme.dart';

/// 🎀 Custom AppBar
/// Responsabilidade: ui-ux-designer-agent / flutter-frontend-agent
/// Garante que o Logo e o nome "Sua Consulta" fiquem visíveis em todas as telas.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showProfileButton;

  const CustomAppBar({
    super.key,
    required this.subtitle,
    this.actions,
    this.bottom,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.primaryBlueDark),
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
                subtitle,
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
        ...?actions,
        if (showProfileButton)
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: AppTheme.primaryBlueDark,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
