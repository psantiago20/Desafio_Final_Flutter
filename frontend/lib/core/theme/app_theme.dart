import 'package:flutter/material.dart';

/// 🎨 AppTheme: Design System for OmniConnect
/// Foco: Interface moderna, Tailwind-inspired (Glassmorphism, clean UI)
class AppTheme {
  // Paleta de Cores Oficial
  static const Color primaryBlueDark = Color(0xFF001D39); 
  static const Color primaryBlue = Color(0xFF0A4174); 
  static const Color primaryBlueLight = Color(0xFFBDD8E9); 
  
  static const Color secondaryBlueDark = Color(0xFF49769F);
  static const Color secondaryBlue = Color(0xFF4E8EA2);
  static const Color secondaryBlueLight = Color(0xFF6EA2B3);
  static const Color accentBlue = Color(0xFF7BBDE8);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF0F4F8), Color(0xFFF9FAFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const Color successGreen = Color(0xFF16A34A); // green-600
  static const Color successGreenLight = Color(0xFFDCFCE7); // green-100
  
  static const Color warningOrange = Color(0xFFEA580C); // orange-600
  static const Color warningOrangeLight = Color(0xFFFFEDD5); // orange-100

  static const Color alertRed = Color(0xFFEF4444); // red-500
  static const Color alertRedLight = Color(0xFFFEE2E2); // red-100

  static const Color backgroundGray = Color(0xFFF9FAFB); // gray-50
  static const Color surfaceWhite = Color(0xFFFFFFFF); // white
  static const Color borderGray = Color(0xFFE5E7EB); // gray-200

  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF4B5563); // gray-600
  static const Color textTertiary = Color(0xFF6B7280); // gray-500

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: successGreen,
        surface: surfaceWhite,
        error: alertRed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textTertiary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderGray, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
class AppColors {
  static const Color primary = AppTheme.primaryBlue;
  static const Color primaryLight = AppTheme.primaryBlueLight;
  static const Color background = AppTheme.backgroundGray;
  static const Color surface = AppTheme.surfaceWhite;
  static const Color surfaceVariant = AppTheme.backgroundGray;
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textHint = AppTheme.textTertiary;
  static const Color border = AppTheme.borderGray;
  static const Color cancelled = AppTheme.alertRed;
  static const Color confirmed = AppTheme.primaryBlue;
  static const Color completed = AppTheme.successGreen;
  static const Color pending = AppTheme.warningOrange;
  static const Color inProgress = AppTheme.secondaryBlue;
}
