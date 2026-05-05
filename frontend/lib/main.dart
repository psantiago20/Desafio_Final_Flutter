import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/client/main_dashboard_screen.dart';

/// 🚀 Entrypoint for OmniConnect Frontend
/// Responsabilidade: flutter-frontend-agent
void main() {
  runApp(const OmniConnectApp());
}

class OmniConnectApp extends StatelessWidget {
  const OmniConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sua Consulta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainDashboardScreen(), // Inicializando com o Dashboard do Cliente
    );
  }
}
