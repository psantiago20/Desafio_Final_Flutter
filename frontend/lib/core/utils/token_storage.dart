import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static SharedPreferences? _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static void saveToken(String token) {
    _prefs?.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static void saveUser(Map<String, dynamic> user) {
    _prefs?.setString(_userKey, jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() {
    final userStr = _prefs?.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  static void clear() {
    _prefs?.remove(_tokenKey);
    _prefs?.remove(_userKey);
  }

  static bool get isAuthenticated => getToken() != null;
}
