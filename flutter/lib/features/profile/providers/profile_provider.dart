import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  UserProfileModel? _profile;

  bool get isLoading => _isLoading;
  UserProfileModel? get profile => _profile;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/v1/user-info/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _profile = UserProfileModel.fromJson(data);
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile(UserProfileModel updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.put(
        '/v1/user-info/me',
        body: updatedProfile.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _profile = UserProfileModel.fromJson(data);
        return null;
      }
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Cập nhật thất bại';
    } catch (e) {
      return 'Lỗi kết nối máy chủ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
