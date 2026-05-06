import 'package:flutter/material.dart';

// Tema global
import 'core/theme/app_theme.dart';

// Páginas
import 'features/auth/pages/splash_page.dart';
import 'features/auth/pages/auth_page.dart';
import 'features/auth/pages/otp_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Tema principal do app
      theme: AppTheme.lightTheme,

      // Tela inicial
      initialRoute: '/',

      // Rotas
      routes: {
        '/': (_) => const SplashPage(),
        '/auth': (_) => const AuthPage(),
        '/otp': (_) => const OtpPage(),
      },
    );
  }
}