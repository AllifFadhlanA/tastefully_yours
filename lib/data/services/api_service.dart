import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  /// Get stored auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save auth token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Remove auth token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Build default headers (with optional auth token)
  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// GET request
  static Future<Map<String, dynamic>> get(
    String url, {
    bool withAuth = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _headers(withAuth: withAuth),
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on HttpException {
      throw Exception('Server tidak dapat dijangkau.');
    }
  }

  /// POST request (JSON body)
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool withAuth = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    }
  }

  /// POST request with multipart (file upload)
  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    File? imageFile,
    String imageFieldName = 'image',
    bool withAuth = false,
    bool isPut = false,
  }) async {
    try {
      final token = withAuth ? await getToken() : null;
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // If updating (PUT), add method override
      if (isPut) {
        request.fields['_method'] = 'PUT';
      }

      request.fields.addAll(fields);

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(imageFieldName, imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    }
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(
    String url, {
    bool withAuth = false,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _headers(withAuth: withAuth),
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    }
  }

  /// Handle HTTP response and throw on error
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login kembali.');
    } else if (response.statusCode == 403) {
      throw Exception('Anda tidak memiliki akses untuk melakukan aksi ini.');
    } else if (response.statusCode == 422) {
      // Validation errors
      final errors = body['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first as String);
        }
      }
      throw Exception(body['message'] as String? ?? 'Validasi gagal.');
    } else {
      throw Exception(body['message'] as String? ?? 'Terjadi kesalahan pada server.');
    }
  }
}
