import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      // Se estiver no system, forçamos um toggle explícito.
      // Pode-se melhorar com `WidgetsBinding.instance.window.platformBrightness` mas
      // como padrão, vamos assumir que queremos ir para o escuro.
      state = ThemeMode.dark;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
