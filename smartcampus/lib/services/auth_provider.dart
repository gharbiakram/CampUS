import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../data/repositories/auth_repository.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider({AuthRepository? authRepository}) {
    _authRepository = authRepository ??
        AuthRepository(
          httpClient: http.Client(),
          secureStorage: const FlutterSecureStorage(),
        );
    _initializeOnce();
  }

  void _initializeOnce() async {
    if (_initialized) return;
    _initialized = true;
    await initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await _authRepository.isLoggedIn();
      if (loggedIn) {
        final email = await _authRepository.getUserEmail();
        _user = User(email: email ?? '', name: 'User');
        _isLoggedIn = true;
      }
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authRepository.login(email, password);
    result.fold(
      (failure) {
        _error = failure.toString();
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _user = user;
        _isLoggedIn = true;
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
    );

    return result.isSuccess;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.logout();
    result.fold(
      (failure) {
        _error = 'Logout error: ${failure.toString()}';
      },
      (_) {
        _user = null;
        _isLoggedIn = false;
        _error = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
