import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return ApiService.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  /// Login user — returns token + user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return ApiService.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  /// Logout (revoke token)
  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConstants.logout, withAuth: true);
    } catch (_) {
      // Even if request fails, clear local token
    } finally {
      await ApiService.removeToken();
    }
  }

  /// Get current user profile
  static Future<UserModel> getProfile() async {
    final response = await ApiService.get(ApiConstants.profile, withAuth: true);
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Format response profil tidak valid.');
    return UserModel.fromJson(data);
  }

  /// Update profile
  static Future<UserModel> updateProfile({
    String? name,
    String? email,
  }) async {
    final response = await ApiService.post(
      ApiConstants.profile,
      withAuth: true,
      body: {
        '_method': 'PUT',
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Format response profil tidak valid.');
    return UserModel.fromJson(data);
  }
}
