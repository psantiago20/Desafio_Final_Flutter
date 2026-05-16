import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/utils/token_storage.dart';
import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

// Estado de autenticação
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  DateTime _lastActivity = DateTime.now();
  Timer? _managementTimer;

  AuthNotifier(this._repository) : super(_getInitialState()) {
    // Configura callbacks globais do API Client
    ApiClient.onUnauthorized = logout;
    ApiClient.onActivity = recordActivity;
    
    // Inicia o monitoramento de sessão se já estiver logado
    if (state.isAuthenticated) {
      _startSessionManagement();
    }
  }

  static AuthState _getInitialState() {
    final storedUser = TokenStorage.getUser();
    if (storedUser != null) {
      try {
        final user = UserModel.fromJson(storedUser);
        final token = TokenStorage.getToken();
        if (token != null) {
          ApiClient.setToken(token);
        }
        return AuthState(user: user);
      } catch (_) {
        return const AuthState();
      }
    }
    return const AuthState();
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  void _startSessionManagement() {
    _managementTimer?.cancel();
    // Verifica a cada 1 minuto
    _managementTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!state.isAuthenticated) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final minutesInactive = now.difference(_lastActivity).inMinutes;

      // 1. Se estiver inativo por mais de 30 minutos, desloga (Inatividade)
      if (minutesInactive >= 30) {
        logout();
        return;
      }

      // 2. Se estiver ativo e o token for "velho" (ex: renovar a cada 15 min), renova
      // Nota: Para simplificar, renovamos se houve atividade recente
      if (minutesInactive < 5) {
         // Verificamos se o token já tem mais de 15 minutos (aproximado pelo tempo de atividade)
         // Para ser preciso precisaríamos guardar a data de criação do token, 
         // mas renovar periodicamente se houver atividade é uma boa estratégia.
         try {
           await _repository.refreshToken();
         } catch (e) {
           // Se falhar a renovação (ex: token já expirou no servidor), logout limpa tudo
           if (e is ApiException && e.statusCode == 401) {
             logout();
           }
         }
      }
    });
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(username, password);
      state = AuthState(user: user);
      recordActivity();
      _startSessionManagement();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
      return false;
    }
  }

  static String _extractMessage(Object e) {
    if (e is ApiException) return e.message;
    return 'Erro inesperado. Tente novamente.';
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String phone,
    required String role,
    String? fullName,
    String? crm,
    String? specialty,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.register(
        email: email,
        username: username,
        password: password,
        phone: phone,
        fullName: fullName,
        role: role,
        crm: crm,
        specialty: specialty,
      );
      return await login(username, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
      return false;
    }
  }

  void logout() {
    _managementTimer?.cancel();
    _repository.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _managementTimer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
