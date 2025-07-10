import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String _baseUrl = dotenv.get('API_URL');
  String? _token;

  // Actualizar token
  void setToken(String? token) {
    _token = token;
  }

  // Headers con token automático
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Métodos HTTP wrapper
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url, headers: _headers);
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {Object? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.patch(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.delete(url, headers: _headers);
  }
}
