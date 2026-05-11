import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/shared/widgets/app_card.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/utils/responsive_helper.dart';
import 'package:frontend/shared/widgets/main_shell.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainShell(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Text(
              "Consultas",
              style: GoogleFonts.dmSans(
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobileSize: 22,
                  desktopSize: 26,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: ResponsiveHelper.getCardSpacing(context)),

            /// FILTROS RESPONSIVOS
            ResponsiveHelper.buildResponsiveLayout(
              context: context,
              mobile: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(f),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  }).toList(),
                ),
              ),
              desktop: Wrap(
                spacing: ResponsiveHelper.getCardSpacing(context) / 2,
                children: _filters.map((f) {
                  return Chip(
                    label: Text(f),
                    backgroundColor: AppColors.surface,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            /// LISTA
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (_, index) {
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "Paciente ${index + 1}",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          "10:00",
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _filters = [
  "Todos",
  "Hoje",
  "Confirmados",
  "Cancelados",
];
