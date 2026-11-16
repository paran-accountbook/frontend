import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    SessionStore? sessionStore,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
       _http = httpClient ?? http.Client(),
       sessionStore = sessionStore ?? SecureSessionStore();

  final String _baseUrl;
  final http.Client _http;
  final SessionStore sessionStore;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(message: 'API_BASE_URL이 설정되지 않았습니다');
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<Object?> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Object?> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<Object?> put(String path, {Object? body, bool authenticated = true}) =>
      _send('PUT', path, body: body, authenticated: authenticated);

  Future<Object?> delete(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('DELETE', path, body: body, authenticated: authenticated);

  Future<Object?> multipartPost(
    String path, {
    required String filePath,
    String field = 'file',
    bool retrying = false,
  }) async {
    final token = await sessionStore.readAccessToken();
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(field, filePath));
    try {
      final streamed = await _http
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 && !retrying && await _refresh()) {
        return multipartPost(
          path,
          filePath: filePath,
          field: field,
          retrying: true,
        );
      }
      return _decode(response);
    } on SocketException {
      throw const ApiException(message: '네트워크 연결을 확인해 주세요');
    } on TimeoutException {
      throw const ApiException(message: '서버 응답이 지연되고 있습니다. 다시 시도해 주세요');
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required bool authenticated,
    bool retrying = false,
  }) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null) uri = uri.replace(queryParameters: query);
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (authenticated) {
      final token = await sessionStore.readAccessToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    try {
      final response = await switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => _http.patch(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => _http.delete(uri, headers: headers, body: jsonEncode(body)),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      }.timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 && authenticated && !retrying) {
        if (await _refresh()) {
          return _send(
            method,
            path,
            body: body,
            query: query,
            authenticated: true,
            retrying: true,
          );
        }
      }
      return _decode(response);
    } on SocketException {
      throw const ApiException(message: '네트워크 연결을 확인해 주세요');
    } on http.ClientException {
      throw const ApiException(message: '서버에 연결할 수 없습니다');
    } on TimeoutException {
      throw const ApiException(message: '서버 응답이 지연되고 있습니다. 다시 시도해 주세요');
    }
  }

  Object? _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        message: '서버 응답 형식이 올바르지 않습니다',
      );
    }
    final envelope = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        code: envelope?['result'] as String?,
        message: envelope?['message'] as String? ?? '요청을 처리하지 못했습니다',
        data: envelope?['data'],
      );
    }
    return envelope != null && envelope.containsKey('data')
        ? envelope['data']
        : decoded;
  }

  Future<bool> _refresh() async {
    final refreshToken = await sessionStore.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final data = await post(
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
        authenticated: false,
      );
      final json = data as Map<String, dynamic>;
      await sessionStore.save(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
      return true;
    } on ApiException {
      await sessionStore.clear();
      return false;
    }
  }
}
