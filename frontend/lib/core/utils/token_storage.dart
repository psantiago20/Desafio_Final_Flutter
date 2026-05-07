/// Armazenamento simples em memória para o token de autenticação.
/// Em produção, substitua por flutter_secure_storage ou shared_preferences.
class TokenStorage {
  static String? _token;
  static Map<String, dynamic>? _user;

  static void saveToken(String token) => _token = token;
  static String? getToken() => _token;
  static void clear() {
    _token = null;
    _user = null;
  }

  static void saveUser(Map<String, dynamic> user) => _user = user;
  static Map<String, dynamic>? getUser() => _user;

  static bool get isAuthenticated => _token != null;
}
