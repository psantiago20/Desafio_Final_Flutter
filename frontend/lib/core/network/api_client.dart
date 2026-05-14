import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // Bypass ngrok interstitial page
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    if (queryParams != null) {
      return uri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  static Future<dynamic> get(String path,
      [Map<String, dynamic>? queryParams]) async {
    try {
      final response =
          await http.get(_uri(path, queryParams), headers: _headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado: $e');
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado. Tente novamente em breve.');
    }
  }

  static Future<dynamic> postForm(String path, Map<String, String> body) async {
    try {
      final formHeaders = {
        'ngrok-skip-browser-warning': 'true',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      final response = await http.post(
        _uri(path),
        headers: formHeaders,
        body: body,
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado. Tente novamente em breve.');
    }
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado. Tente novamente em breve.');
    }
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado. Tente novamente em breve.');
    }
  }

  static Future<void> delete(String path) async {
    try {
      final response =
          await http.delete(_uri(path), headers: _headers);
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleResponse(response);
      }
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: _mapClientError(e.message));
    } catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Ocorreu um erro inesperado. Tente novamente em breve.');
    }
  }

  static String _mapClientError(String originalError) {
    if (originalError.contains('Failed to fetch') || 
        originalError.contains('XMLHttpRequest') ||
        originalError.contains('Connection refused')) {
      return 'O sistema está temporariamente fora do ar para manutenção. Já estamos trabalhando nisso!';
    }
    return 'Ops! Tivemos um problema de conexão. Por favor, tente novamente.';
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    if (response.statusCode == 401) {
      throw ApiException(statusCode: 401, message: 'Sua sessão expirou ou os dados de acesso estão incorretos.');
    }

    if (response.statusCode == 403) {
      throw ApiException(statusCode: 403, message: 'Você não tem permissão para realizar esta ação.');
    }

    if (response.statusCode >= 500) {
      throw ApiException(statusCode: response.statusCode, message: 'O sistema encontrou uma falha momentânea. Nossa equipe já foi notificada.');
    }

    String message = 'Ocorreu um erro inesperado. Tente de novo.';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      message = body['detail'] ?? body['message'] ?? message;
      
      // Tradução de mensagens comuns do backend
      if (message.toLowerCase().contains('invalid credentials')) {
        message = 'Usuário ou senha incorretos. Por favor, verifique seus dados.';
      }
    } catch (_) {}

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}

