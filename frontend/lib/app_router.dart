import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'features/auth/screens/auth_page.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/appointments/screens/appointments_screen.dart';
import 'features/appointments/screens/appointment_detail_screen.dart';
import 'features/appointments/screens/new_appointment_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/patients/screens/patients_screen.dart';
import 'features/patients/screens/patient_appointments_screen.dart';
import 'shared/models/patient_model.dart';
import 'shared/models/appointment_model.dart';
import 'shared/widgets/main_shell.dart';
import 'features/client/screens/main_dashboard_screen.dart' as client_screens;
import 'features/landing/screens/landing_page.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watch only navigation-relevant state to prevent unnecessary router recreation
  final authState = ref.watch(authProvider.select((s) => (
    userId: s.user?.id,
    role: s.user?.role,
    isAuthenticated: s.user != null,
  )));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: kIsWeb
        ? '/'
        : (authState.isAuthenticated
              ? (authState.role == 'admin'
                    ? '/management-v1'
                    : (authState.role == 'doctor'
                          ? '/dashboard'
                          : '/client'))
              : '/login'),

    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final role = authState.role;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isHomeRoute = state.matchedLocation == '/';

      if (kIsWeb) {
        // Lógica Web: Permite Landing Page (/)
        if (!isAuthenticated) {
          if (isHomeRoute || isAuthRoute) return null;
          return '/';
        }

        if (isAuthenticated) {
          final isAdmin = role == 'admin';
          final isDoctor = role == 'doctor';
          if (isAuthRoute || isHomeRoute) {
            if (isAdmin) return '/management-v1';
            return isDoctor ? '/dashboard' : '/client';
          }
        }
      } else {
        // Lógica Mobile: Mantém o comportamento original
        if (!isAuthenticated && !isAuthRoute) return '/login';

        if (isAuthenticated) {
          final isAdmin = role == 'admin';
          final isDoctor = role == 'doctor';
          if (isAuthRoute || isHomeRoute) {
            if (isAdmin) return '/management-v1';
            return isDoctor ? '/dashboard' : '/client';
          }

          if (!isDoctor && state.matchedLocation == '/dashboard') {
            return '/client';
          }
        }
      }

      // Proteção Global para a Rota de Admin
      if (state.matchedLocation == '/management-v1') {
        if (!isAuthenticated) return '/';
        if (role != 'admin') return '/';
      }

      return null;
    },
    routes: [
      // Home / Landing Page (Apenas Web ou acessível via /)
      GoRoute(path: '/', builder: (_, _) => const LandingPage()),

      // Auth
      GoRoute(path: '/login', builder: (_, _) => const AuthPage()),

      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // App (com shell de navegação)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (_, _) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (_, _) => const PatientsScreen(),
            routes: [
              GoRoute(
                path: 'appointments',
                builder: (context, state) {
                  final patient = state.extra as PatientModel;
                  return PatientAppointmentsScreen(patient: patient);
                },
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),

      // Telas fora do shell
      GoRoute(
        path: '/appointments/new',
        builder: (_, _) => const NewAppointmentScreen(),
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
        builder: (_, _) => const client_screens.MainDashboardScreen(),
      ),
      GoRoute(
        path: '/management-v1',
        builder: (_, _) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página não encontrada: ${state.uri}')),
    ),
  );
});
