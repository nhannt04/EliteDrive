import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../customer/models/rental.dart';

class StaffRentalProvider extends ChangeNotifier {
  List<Rental> _rentals = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _totalElements = 0;
  int _totalPages = 0;
  int _currentPage = 0;
  
  // Stats
  int _totalCount = 0;
  int _pendingCount = 0;
  int _rentingCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _totalRevenue = 0.0;

  List<Rental> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get totalElements => _totalElements;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;

  int get totalCount => _totalCount;
  int get pendingCount => _pendingCount;
  int get rentingCount => _rentingCount;
  int get completedCount => _completedCount;
  int get cancelledCount => _cancelledCount;
  double get totalRevenue => _totalRevenue;

  Future<void> fetchAllRentals({
    String status = 'ALL',
    String keyword = '',
    int page = 0,
    int size = 50,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Build parameters
      String path = '/v1/rentals?page=$page&size=$size&sort=createdDate,desc';
      if (status != 'ALL' && status.isNotEmpty) {
        path += '&status=$status';
      }
      if (keyword.isNotEmpty) {
        path += '&keyword=${Uri.encodeComponent(keyword)}';
      }

      final response = await ApiClient.get(path);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> content = decoded['content'] ?? [];
        _rentals = content.map((json) => Rental.fromJson(json)).toList();
        _totalElements = decoded['totalElements'] ?? 0;
        _totalPages = decoded['totalPages'] ?? 0;
        _currentPage = decoded['number'] ?? 0;

        // Calculate Stats based on local/returned data or general metrics
        _calculateStats();
      } else {
        _errorMessage = 'Không thể tải danh sách đơn thuê. Lỗi ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối máy chủ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStats() {
    _totalCount = _totalElements;
    _pendingCount = 0;
    _rentingCount = 0;
    _completedCount = 0;
    _cancelledCount = 0;
    _totalRevenue = 0.0;

    for (var rental in _rentals) {
      final s = rental.status.toUpperCase();
      if (s == 'PENDING') {
        _pendingCount++;
      } else if (s == 'RENTING') {
        _rentingCount++;
      } else if (s == 'COMPLETED') {
        _completedCount++;
        _totalRevenue += rental.totalPrice;
      } else if (s == 'CANCELLED') {
        _cancelledCount++;
      }
    }
  }

  Future<bool> updateRentalStatus(
    int rentalId,
    String status, {
    String? cancelReason,
  }) async {
    try {
      final body = {
        'status': status,
        if (status == 'CANCELLED' && cancelReason != null) 'cancelReason': cancelReason,
      };

      final response = await ApiClient.put(
        '/v1/rentals/$rentalId/status',
        body: body,
      );

      if (response.statusCode == 200) {
        // Find and update local list element status to avoid full reload lag
        final index = _rentals.indexWhere((r) => r.rentalId == rentalId);
        if (index != -1) {
          final oldRental = _rentals[index];
          _rentals[index] = Rental(
            rentalId: oldRental.rentalId,
            customerName: oldRental.customerName,
            customerEmail: oldRental.customerEmail,
            startDate: oldRental.startDate,
            endDate: oldRental.endDate,
            totalPrice: oldRental.totalPrice,
            status: status,
            createdDate: oldRental.createdDate,
            carId: oldRental.carId,
            carName: oldRental.carName,
            brand: oldRental.brand,
            thumbnailUrl: oldRental.thumbnailUrl,
            seats: oldRental.seats,
            transmission: oldRental.transmission,
          );
          _calculateStats();
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Rental?> fetchRentalDetail(int rentalId) async {
    try {
      final response = await ApiClient.get('/v1/rentals/$rentalId');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Rental.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}
