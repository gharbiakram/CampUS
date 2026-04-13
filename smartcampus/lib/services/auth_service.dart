import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();

  /// Log in with email and password
  /// Returns User object with token on success
  static Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User(
          email: email,
          token: data['access_token'] ?? data['token'],
          name: data['name'],
        );

        // Store token and email securely
        await _secureStorage.write(
          key: secureStorageTokenKey,
          value: user.token,
        );
        await _secureStorage.write(
          key: secureStorageEmailKey,
          value: email,
        );

        return user;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Retrieve stored token from secure storage
  static Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: secureStorageTokenKey);
  }

  /// Retrieve stored email from secure storage
  static Future<String?> getStoredEmail() async {
    return await _secureStorage.read(key: secureStorageEmailKey);
  }

  /// Check if user is logged in (token exists)
  static Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  /// Log out: clear stored credentials
  static Future<void> logout() async {
    await _secureStorage.delete(key: secureStorageTokenKey);
    await _secureStorage.delete(key: secureStorageEmailKey);
  }
}
