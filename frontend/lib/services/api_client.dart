import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Thin HTTP client that attaches the JWT bearer token to every request and
/// centralizes base-url/error handling for the whole app.
class ApiClient {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  String? _cachedToken;

  Future<String?> get token async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveSession(String token, int userId) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final t = await token;
    return {
      if (json) 'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<dynamic> get(String path) async {
    final response = await http.get(_uri(path), headers: await _headers());
    return _handle(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<http.StreamedResponse> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String fileFieldName,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers(json: false));
    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: filename,
      ),
    );
    return request.send();
  }

  Future<List<int>> postForBytes(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(response.statusCode, response.body);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        return jsonDecode(response.body);
      }
      return response.body;
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic> && payload['message'] is String) {
        return payload['message'] as String;
      }
    } on FormatException {
      // Non-JSON responses are already suitable for display.
    }
    return body.isNotEmpty ? body : 'Request failed ($statusCode)';
  }
}
