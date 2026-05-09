import 'dart:convert';
import 'dart:io';
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
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
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
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
    }
  }

  static Future<dynamic> postForm(String path, Map<String, String> body) async {
    try {
      // For form posts we need to merge ngrok header manually (body is Map<String,String>)
      final formHeaders = {
        'ngrok-skip-browser-warning': 'true',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      final response = await http.post(
        _uri(path),
        headers: formHeaders,
        body: body, // http package automatically sets content-type to application/x-www-form-urlencoded
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
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
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
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
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
    }
  }

  static Future<void> delete(String path) async {
    try {
      final response =
          await http.delete(_uri(path), headers: _headers);
      if (response.statusCode != 204 && response.statusCode != 200) {
        _handleResponse(response);
      }
    } on SocketException {
      throw ApiException(
          statusCode: 0, message: 'Sem conexão com o servidor.');
    } on http.ClientException catch (e) {
      throw ApiException(
          statusCode: 0, message: 'Falha de conexão: ${e.message}');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = 'Erro desconhecido';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      message = body['detail'] ?? body['message'] ?? message;
    } catch (_) {}

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
