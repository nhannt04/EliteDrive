import 'package:flutter/material.dart';
import '../models/car.dart';
import '../../../../main.dart';
import '../../../core/theme/app_theme.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Car car;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;

  const BookingSuccessScreen({
    super.key,
    required this.car,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hoàn tất đặt xe'),
        automaticallyImplyLeading: false, // Prevents going back
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered Green CheckCircle
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Center(
                        child: Text(
                          'Đặt xe thành công!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Center(
                        child: Text(
                          'Cảm ơn bạn đã lựa chọn dịch vụ của EliteDrive. Yêu cầu thuê xe ${car.carName} của bạn đã được tiếp nhận và đang chờ nhân viên liên hệ xác nhận.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.subTextColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Detail box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Trạng thái đơn hàng:', 'Đang chờ duyệt', isPrimaryColor: true),
                            const SizedBox(height: 12),
                            _buildInfoRow('Phương thức thanh toán:', 'Thanh toán sau (CARD)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Primary Dark Button: QUẢN LÝ CHUYẾN ĐI CỦA TÔI
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B), // Slate/Dark background
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Pill rounded
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(initialIndex: 2), // Go to Rental History Tab
                            ),
                            (route) => false,
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'QUẢN LÝ CHUYẾN ĐI CỦA TÔI',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Text Button: Quay về Trang chủ
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.subTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(initialIndex: 0), // Go to Home Tab
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Quay về Trang chủ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrimaryColor = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.subTextColor, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isPrimaryColor ? AppTheme.primaryColor : AppTheme.textColor,
          ),
        ),
      ],
    );
  }
}
