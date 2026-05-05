import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/exceptions/app_exception.dart';
import '../../core/result_model.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';

/// Repository for authentication operations
class AuthRepository {
  final http.Client httpClient;
  final FlutterSecureStorage secureStorage;

  AuthRepository({
    required this.httpClient,
    required this.secureStorage,
  });

  /// Get stored token
  Future<String?> getToken() async {
    try {
      return await secureStorage.read(key: 'auth_token');
    } catch (e) {
      throw StorageException(message: 'Failed to retrieve token: $e');
    }
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    try {
      return await secureStorage.read(key: 'user_email');
    } catch (e) {
      throw StorageException(message: 'Failed to retrieve email: $e');
    }
  }

  /// Save token and email
  Future<void> saveToken(String token, String email) async {
    try {
      await Future.wait([
        secureStorage.write(key: 'auth_token', value: token),
        secureStorage.write(key: 'user_email', value: email),
      ]);
    } catch (e) {
      throw StorageException(message: 'Failed to save token: $e');
    }
  }

  /// Clear stored credentials
  Future<void> clearCredentials() async {
    try {
      await Future.wait([
        secureStorage.delete(key: 'auth_token'),
        secureStorage.delete(key: 'user_email'),
      ]);
    } catch (e) {
      throw StorageException(message: 'Failed to clear credentials: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Login with email and password
  Future<Result<User>> login(String email, String password) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return Failure(ValidationException(
          message: 'Email and password cannot be empty',
        ));
      }

      if (!email.contains('@')) {
        return Failure(ValidationException(
          message: 'Invalid email format',
        ));
      }

      // Make API call
      final response = await httpClient
          .post(
            Uri.parse('$apiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw NetworkException(message: 'Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final name = data['name'] as String?;

        if (token == null) {
          return Failure(NetworkException(
            message: 'Invalid response format',
            statusCode: response.statusCode,
          ));
        }

        // Save token
        await saveToken(token, email);

        // Create user object
        final user = User(
          email: email,
          name: name ?? 'User',
        );

        return Success(user);
      } else if (response.statusCode == 401) {
        return Failure(AuthException(
          message: 'Invalid email or password',
        ));
      } else {
        return Failure(NetworkException(
          message: 'Login failed: ${response.statusCode}',
          statusCode: response.statusCode,
        ));
      }
    } on ValidationException catch (e) {
      return Failure(e);
    } on NetworkException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException(
        message: 'Login error: ${e.toString()}',
      ));
    }
  }

  /// Logout
  Future<Result<void>> logout() async {
    try {
      final token = await getToken();
      
      if (token != null) {
        // Try to notify backend
        try {
          await httpClient
              .post(
                Uri.parse('$apiBaseUrl/auth/logout'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Ignore backend errors, continue with local logout
        }
      }

      // Clear local credentials
      await clearCredentials();
      return Success(null);
    } catch (e) {
      return Failure(StorageException(
        message: 'Logout failed: ${e.toString()}',
      ));
    }
  }
}

