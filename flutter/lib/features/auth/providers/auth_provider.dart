import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _username;
  String? _fullName;
  String? _avatarUrl;
  List<String> _roles = [];

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;
  List<String> get roles => _roles;

  Future<void> tryAutoLogin() async {
    final token = await ApiClient.getToken();
    if (token == null) return;

    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
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
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithToken(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      String cleanToken = token.replaceFirst('Bearer ', '');
      await ApiClient.saveToken(cleanToken);
      _isAuthenticated = true;
      await tryAutoLogin();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
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
      return response.statusCode == 200;
    } catch (e) {
      return false;
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
