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

  AuthNotifier(this._repository) : super(_getInitialState());

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

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(username, password);
      state = AuthState(user: user);
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
      // Após cadastro, faz login automaticamente
      return await login(username, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
      return false;
    }
  }

  void logout() {
    _repository.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
