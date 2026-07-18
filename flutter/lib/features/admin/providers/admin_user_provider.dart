import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../profile/models/user_profile_model.dart';

class AdminUserProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<UserProfileModel> _users = [];

  bool get isLoading => _isLoading;
  List<UserProfileModel> get users => _users;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/v1/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => UserProfileModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post('/v1/users', body: data);
      if (response.statusCode == 200) {
        await fetchAllUsers(); // Reload list
        return null;
      }
      final responseData = jsonDecode(response.body);
      return responseData['message'] ?? 'Thêm người dùng thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> disableUser(int id) async {
    try {
      final response = await ApiClient.put('/v1/users/$id/disable');
      if (response.statusCode == 200) {
        final index = _users.indexWhere((u) => u.userId == id);
        if (index != -1) {
          // Update local state instead of refetching for better UX
          final oldUser = _users[index];
          _users[index] = UserProfileModel(
            userId: oldUser.userId,
            username: oldUser.username,
            fullName: oldUser.fullName,
            address: oldUser.address,
            email: oldUser.email,
            phoneNumber: oldUser.phoneNumber,
            avatarUrl: oldUser.avatarUrl,
            dateOfBirth: oldUser.dateOfBirth,
            identifyId: oldUser.identifyId,
            driverLicenceId: oldUser.driverLicenceId,
            roles: oldUser.roles,
            isEnabled: false,
            userType: oldUser.userType,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> enableUser(int id) async {
    try {
      final response = await ApiClient.put('/v1/users/$id/enable');
      if (response.statusCode == 200) {
        final index = _users.indexWhere((u) => u.userId == id);
        if (index != -1) {
          final oldUser = _users[index];
          _users[index] = UserProfileModel(
            userId: oldUser.userId,
            username: oldUser.username,
            fullName: oldUser.fullName,
            address: oldUser.address,
            email: oldUser.email,
            phoneNumber: oldUser.phoneNumber,
            avatarUrl: oldUser.avatarUrl,
            dateOfBirth: oldUser.dateOfBirth,
            identifyId: oldUser.identifyId,
            driverLicenceId: oldUser.driverLicenceId,
            roles: oldUser.roles,
            isEnabled: true,
            userType: oldUser.userType,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await ApiClient.delete('/v1/users/$id');
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.userId == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
