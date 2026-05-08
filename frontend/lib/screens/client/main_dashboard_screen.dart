import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'results_screen.dart';
import 'chat_screen.dart';

/// 📱 Main Dashboard
/// Responsabilidade: flutter-frontend-agent
/// Casca principal que controla a navegação entre Home, Agenda, Resultados, Mensagens e Perfil.
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  void _navigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _navigate),
    const AgendaScreen(),
    const ChatScreen(),
    const ResultsScreen(),
    const Scaffold(body: Center(child: Text('Alertas e Notificações'))), // Placeholder para Alertas
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigate,
        backgroundColor: AppTheme.surfaceWhite,
        indicatorColor: AppTheme.primaryBlueDark,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: 'Consultas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Colors.white),
            label: 'Exames',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: Colors.white),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

