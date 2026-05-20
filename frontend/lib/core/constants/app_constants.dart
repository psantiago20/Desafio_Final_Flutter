import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  /// Retorna a URL base correta dependendo da plataforma.
  /// Configurada exclusivamente via .env (API_URL_WEB ou API_URL_MOBILE).
  static String get baseUrl {
    if (kIsWeb) {
      final envUrl = dotenv.env['API_URL_WEB'] ?? dotenv.env['API_URL'];
      if (envUrl != null && envUrl.isNotEmpty && !envUrl.contains('localhost')) {
        return envUrl;
      }
      return Uri.base.origin;
    }
    final key = 'API_URL_MOBILE';
    final url = dotenv.env[key] ?? dotenv.env['API_URL'];
    assert(url != null && url.isNotEmpty, 'Variável $key (ou API_URL) não definida no .env');
    return url!;
  }

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
