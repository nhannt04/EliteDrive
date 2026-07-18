import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/rental.dart';

class CustomerProvider extends ChangeNotifier {
  List<Rental> _rentals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Rental> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchMyRentals({String? status}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String url = '/v1/rentals/my?page=0&size=50&sort=createdDate,desc';
      if (status != null && status != 'ALL') {
        url += '&status=$status';
      }
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> content = decoded['content'] ?? [];
        _rentals = content.map((json) => Rental.fromJson(json)).toList();
        print('fetchMyRentals SUCCESS: fetched ${_rentals.length} rentals');
        for (var r in _rentals) {
          print('Rental ID: ${r.rentalId}, Car: ${r.carName}, Dates: ${r.startDate} to ${r.endDate}, Price: ${r.totalPrice}, Status: ${r.status}');
        }
      } else {
        _errorMessage = 'Không thể tải lịch sử thuê xe. Lỗi ${response.statusCode}';
        print('fetchMyRentals ERROR: status ${response.statusCode}');
      }
    } catch (e, stack) {
      _errorMessage = 'Lỗi kết nối máy chủ: $e';
      print('fetchMyRentals EXCEPTION: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createPayOSLink(int rentalId) async {
    try {
      final response = await ApiClient.post('/v1/payments/create-link/$rentalId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['checkoutUrl'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> confirmPaymentStatus(int rentalId) async {
    try {
      final response = await ApiClient.post('/v1/payments/confirm/$rentalId');
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> cancelRental(int rentalId, String reason) async {
    try {
      final response = await ApiClient.delete(
        '/v1/rentals/my/$rentalId',
        body: {'cancelReason': reason},
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
