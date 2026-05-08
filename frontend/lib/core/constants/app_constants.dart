class AppConstants {
  // Troque pelo IP da sua máquina quando rodar no emulador/dispositivo físico
<<<<<<< HEAD
  static const String baseUrl = 'http://localhost:8000'; // Alterado para localhost pois está rodando no Chrome

=======
  static const String baseUrl = 'http://10.0.2.2:8000';
>>>>>>> origin/development

  // Auth
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';

  // Appointments
  static const String appointmentsEndpoint = '/api/appointments';

  // Dashboard
  static const String dashboardStatsEndpoint = '/api/dashboard/stats';
  static const String todayAppointmentsEndpoint = '/api/dashboard/appointments/today';
  static const String upcomingAppointmentsEndpoint = '/api/dashboard/appointments/upcoming';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
}
