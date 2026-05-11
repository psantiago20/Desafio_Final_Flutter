import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/main_shell.dart';
import 'package:frontend/shared/widgets/app_card.dart';
import 'package:frontend/shared/utils/responsive_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainShell(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: ResponsiveHelper.buildResponsiveLayout(
          context: context,
          mobile: _mobileLayout(context),
          desktop: _desktopLayout(context),
        ),
      ),
    );
  }

  /// ✅ MOBILE
  Widget _mobileLayout(BuildContext context) {
    return Column(
      children: [_avatar(context), const SizedBox(height: 20), _info(context)],
    );
  }

  /// ✅ DESKTOP
  Widget _desktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _avatar(context)),
        const SizedBox(width: 40),
        Expanded(flex: 2, child: _info(context)),
      ],
    );
  }

  /// ✅ AVATAR (CORRIGIDO)
  Widget _avatar(BuildContext context) {
    final size = ResponsiveHelper.getAvatarSize(context);

    return AppCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: size / 2.2, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// ✅ INFO (CORRIGIDO)
  Widget _info(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amanda de Souza",
            style: GoogleFonts.dmSans(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobileSize: 16,
                desktopSize: 18,
              ),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "amanda@email.com",
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          /// CAMPOS
          _field("Especialidade", "Clínico Geral"),
          const SizedBox(height: 12),
          _field("Telefone", "(83) 99999-9999"),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(value, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
