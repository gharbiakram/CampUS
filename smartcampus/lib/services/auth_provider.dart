import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  /// Constructor: Initialize session on app startup
  AuthProvider() {
    _initializeOnce();
  }

  /// Initialize only once when app starts
  void _initializeOnce() async {
    if (_initialized) return;
    _initialized = true;
    await initialize();
  }

  /// Initialize: check if user was previously logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        final email = await AuthService.getStoredEmail();
        final token = await AuthService.getStoredToken();
        _user = User(email: email ?? '', token: token);
        _isLoggedIn = true;
      }
    } catch (e) {
      _error = 'Initialization error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Log in with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.login(email, password);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _user = null;
      _isLoggedIn = false;
      _error = null;
    } catch (e) {
      _error = 'Logout error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
