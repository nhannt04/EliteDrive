import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isCheckingAuth = true; // Initially true when app starts
  String? _username;
  String? _fullName;
  String? _avatarUrl;
  List<String> _roles = [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  List<String> get roles => _roles;

  Future<void> tryAutoLogin() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      _isCheckingAuth = false;
      notifyListeners();
      return;
    }

    _isCheckingAuth = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isAuthenticated = true;
        _username = data['username'];
        _fullName = data['fullName'];
        _avatarUrl = data['avatarUrl'];
        if (data['authorities'] != null) {
          _roles = (data['authorities'] as List)
              .map((auth) => auth['authority'].toString())
              .toList();
        }
      } else {
        await logout();
      }
    } catch (e) {
      // Offline/network failure - keep cached state if exists or clear
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/auth/login',
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token != null) {
          // Spring Boot prefix might include "Bearer " - remove if it doesn't, but ApiClient prepends Bearer,
          // so let's clean the token string.
          String cleanToken = token.toString().replaceFirst('Bearer ', '');
          await ApiClient.saveToken(cleanToken);
          _isAuthenticated = true;
          await tryAutoLogin();
          return null;
        }
      }
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Đăng nhập thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loginWithToken(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      String cleanToken = token.replaceFirst('Bearer ', '');
      await ApiClient.saveToken(cleanToken);
      _isAuthenticated = true;
      await tryAutoLogin();
      return null;
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String address,
    required String identifyId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/auth/register',
        body: {
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'address': address,
          'identifyId': identifyId,
        },
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Đăng ký thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/auth/forgot-password',
        body: {'email': email},
      );
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại.';
      }
    } catch (e) {
      return 'Lỗi kết nối máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final int otpCode = int.tryParse(otp) ?? 0;
      final response = await ApiClient.post(
        '/auth/verify-otp',
        body: {'email': email, 'otpCode': otpCode},
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Xác thực OTP thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/auth/reset-password',
        body: {'token': token, 'newPassword': newPassword},
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Đổi mật khẩu thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/auth/change-password',
        body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Đổi mật khẩu thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout');
    } catch (_) {}
    await ApiClient.clearToken();
    _isAuthenticated = false;
    _username = null;
    _fullName = null;
    _avatarUrl = null;
    _roles = [];
    notifyListeners();
  }
}
