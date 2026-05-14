import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final bool showText;
  final double iconSize;
  final double fontSize;
  final Color? colorOverride;

  const AppLogo({
    super.key,
    this.showText = true,
    this.iconSize = 24,
    this.fontSize = 22,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = colorOverride ?? Theme.of(context).colorScheme.primary;

    // Light Mode: círculo azul vívido (#0052CC) + ícone branco + texto azul
    // Dark Mode:  círculo branco + ícone azul vívido (#0052CC) + texto branco
    const Color vividBlue   = Color(0xFF0052CC);
    final Color circleBg    = isDark ? Colors.white : vividBlue;
    final Color iconColor   = isDark ? vividBlue    : Colors.white;
    final Color textColor   = isDark ? Colors.white : vividBlue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconSize / 3),
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.health_and_safety,
            color: iconColor,
            size: iconSize,
          ),
        ),
        if (showText) ...[
          SizedBox(width: iconSize / 2),
          Text(
            'Sua Consulta',
            style: GoogleFonts.manrope(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
