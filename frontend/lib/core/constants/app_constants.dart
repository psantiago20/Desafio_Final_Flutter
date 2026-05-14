import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Troque pelo IP da sua máquina quando rodar no emulador/dispositivo físico
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000';

  // Auth
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';

  // Appointments
  static const String appointmentsEndpoint = '/api/appointments';
  static const String examsEndpoint = '/api/exams';

  // Dashboard
  static const String dashboardStatsEndpoint = '/api/dashboard/stats';
  static const String todayAppointmentsEndpoint = '/api/dashboard/appointments/today';
  static const String upcomingAppointmentsEndpoint = '/api/dashboard/appointments/upcoming';

  // Patients
  static const String patientsEndpoint = '/api/patients';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
}
