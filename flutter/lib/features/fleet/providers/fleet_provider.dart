import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/car.dart';

class FleetProvider extends ChangeNotifier {
  List<Car> _cars = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Car> get cars => _cars;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchCars({
    String keyword = '',
    String sort = 'pricePerDay,asc',
    String? brand,
    int? seats,
    double? maxPrice,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      var path = '/v1/cars?keyword=$keyword&page=0&size=50&sort=$sort';
      if (brand != null && brand.isNotEmpty) {
        path += '&brand=$brand';
      }
      if (seats != null) {
        path += '&seats=$seats';
      }
      if (maxPrice != null) {
        path += '&maxPrice=${maxPrice.toInt()}';
      }
      if (startDate != null && startDate.isNotEmpty) {
        path += '&startDate=$startDate';
      }
      if (endDate != null && endDate.isNotEmpty) {
        path += '&endDate=$endDate';
      }
      
      final response = await ApiClient.get(path);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> content = decoded['content'] ?? [];
        _cars = content.map((json) => Car.fromJson(json)).toList();
      } else {
        _errorMessage = 'Không thể tải danh sách xe. Lỗi ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối máy chủ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Car?> fetchCarDetail(int id) async {
    try {
      final response = await ApiClient.get('/v1/cars/$id');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Car.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createBooking(int carId, DateTime startDate, DateTime endDate, String notes) async {
    try {
      final response = await ApiClient.post(
        '/v1/rentals',
        body: {
          'carId': carId,
          'startDate': startDate.toIso8601String().substring(0, 10), // yyyy-MM-dd
          'endDate': endDate.toIso8601String().substring(0, 10),     // yyyy-MM-dd
          'notes': notes,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
