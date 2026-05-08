import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/utils/token_storage.dart';
import 'package:frontend/shared/models/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String username, String password) async {
    final data = await ApiClient.postForm(AppConstants.loginEndpoint, {
      'username': username,
      'password': password,
    });

    final token = data['access_token'] as String;
    TokenStorage.saveToken(token);
    ApiClient.setToken(token);

    final user = await getMe();
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String role = 'doctor',
  }) async {
    final data = await ApiClient.post(AppConstants.registerEndpoint, {
      'email': email,
      'username': username,
      'password': password,
      if (fullName != null) 'full_name': fullName,
      'role': role,
    });

    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final data = await ApiClient.get(AppConstants.meEndpoint);
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    TokenStorage.saveUser(user.toJson());
    return user;
  }

  void logout() {
    TokenStorage.clear();
    ApiClient.clearToken();
  }
}
