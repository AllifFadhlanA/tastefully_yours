import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check token on app start
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        _user = await AuthService.getProfile();
        _status = AuthStatus.authenticated;
      } catch (_) {
        await ApiService.removeToken();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Login
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await AuthService.login(email: email, password: password);
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Format response tidak valid.');
      final token = data['token'] as String?;
      if (token == null) throw Exception('Token tidak ditemukan dalam response.');
      await ApiService.saveToken(token);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await AuthService.register(
        name: name,
        email: email,
        password: password,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Format response tidak valid.');
      final token = data['token'] as String?;
      if (token == null) throw Exception('Token tidak ditemukan dalam response.');
      await ApiService.saveToken(token);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    try {
      _user = await AuthService.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
