import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/custom_app_bar.dart';
import 'package:frontend/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final dateFmt = DateFormat("dd/MM/yyyy");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(subtitle: 'Meu Perfil', showProfileButton: false, showThemeButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'M',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 36, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.salutationName,
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(user.role),
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // Info card
            _InfoCard(
              items: [
                _InfoItem(
                  icon: Icons.person_outline,
                  label: 'Usuário',
                  value: user.username,
                ),
                _InfoItem(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: user.email,
                ),
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Membro desde',
                  value: dateFmt.format(user.createdAt),
                ),
                _InfoItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Status',
                  value: user.isActive ? 'Ativo' : 'Inativo',
                  valueColor:
                      user.isActive ? AppColors.completed : AppColors.cancelled,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Sair — só visível no app mobile (web tem o menu lateral) ──────
            if (!kIsWeb) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cancelled,
                    side: const BorderSide(color: AppColors.cancelled),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _confirmLogout(context),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'doctor':
        return 'Médico';
      case 'admin':
        return 'Administrador';
      case 'receptionist':
        return 'Recepcionista';
      default:
        return role;
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.cancelled, size: 24),
            const SizedBox(width: 12),
            const Text('Sair da conta'),
          ],
        ),
        content: const Text(
            'Tem certeza que deseja sair? Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.cancelled),
            child: Text(
              'Sair',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textHint),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.valueColor ??
                                  AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionItem(
      {required this.icon, required this.label, required this.onTap});
}

class _ActionCard extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0) const Divider(height: 1),
              ListTile(
                leading: Icon(item.icon, color: AppColors.primary),
                title: Text(item.label,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
                onTap: item.onTap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
