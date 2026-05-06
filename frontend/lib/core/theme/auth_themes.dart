import 'package:flutter/material.dart';
import 'app_theme.dart';

class AuthThemes {
  static ThemeData base = AppTheme.lightTheme;

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ThemeData login = base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _buttonStyle,
    ),
  );

  static ThemeData register = base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _buttonStyle,
    ),
  );
}