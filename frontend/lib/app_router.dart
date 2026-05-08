import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/pages/auth_page.dart';

import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
import 'features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'features/appointments/presentation/screens/new_appointment_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'shared/models/appointment_model.dart';
import 'shared/widgets/main_shell.dart';
import 'screens/client/main_dashboard_screen.dart' as client_screens;


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated 
        ? (authState.user?.role == 'doctor' ? '/dashboard' : '/client') 
        : '/login',

    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated) {
        final isDoctor = authState.user?.role == 'doctor';
        
        if (isAuthRoute) {
          return isDoctor ? '/dashboard' : '/client';
        }
        
        if (!isDoctor && state.matchedLocation == '/dashboard') {
          return '/client';
        }
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const AuthPage()),

      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // App (com shell de navegação)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (_, __) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Telas fora do shell
      GoRoute(
        path: '/appointments/new',
        builder: (_, __) => const NewAppointmentScreen(),
      ),
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) {
          final appointment = state.extra as AppointmentModel;
          return AppointmentDetailScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/client',
        builder: (_, __) => const client_screens.MainDashboardScreen(),
      ),

    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
});
