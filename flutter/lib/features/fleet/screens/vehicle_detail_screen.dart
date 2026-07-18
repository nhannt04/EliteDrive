import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fleet_provider.dart';
import '../models/car.dart';
import 'booking_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int carId;
  const VehicleDetailScreen({super.key, required this.carId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Car? _car;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  void _loadCar() async {
    final car = await context.read<FleetProvider>().fetchCarDetail(widget.carId);
    if (mounted) {
      setState(() {
        _car = car;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_car == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy thông tin xe.')),
      );
    }

    final car = _car!;

    return Scaffold(
      appBar: AppBar(
        title: Text(car.carName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            car.thumbnailUrl != null && car.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    ApiClient.resolveImageUrl(car.thumbnailUrl),
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 250,
                      color: const Color(0xFFE9ECEF),
                      child: const Icon(Icons.directions_car, size: 100, color: AppTheme.subTextColor),
                    ),
                  )
                : Container(
                    height: 250,
                    color: const Color(0xFFE9ECEF),
                    child: const Icon(Icons.directions_car, size: 100, color: AppTheme.subTextColor),
                  ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.brand.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    car.carName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đời xe: ${car.year} | Model: ${car.model}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thông số kỹ thuật',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildSpecCard(Icons.people, 'Sức chứa', '${car.seats} chỗ', const Color(0xFF3B82F6)),
                      _buildSpecCard(Icons.settings, 'Hộp số', car.transmission == 'AUTOMATIC' ? 'Tự động' : 'Số sàn', const Color(0xFF10B981)),
                      _buildSpecCard(Icons.local_gas_station, 'Nhiên liệu', car.fuelType == 'GASOLINE' ? 'Xăng' : 'Dầu', const Color(0xFFF59E0B)),
                      _buildSpecCard(Icons.speed, '0-100 km/h', '3.5 giây', const Color(0xFFEF4444)),
                      _buildSpecCard(Icons.badge, 'Biển số', car.licensePlate, const Color(0xFF8B5CF6)),
                      _buildSpecCard(Icons.color_lens, 'Màu sắc', car.color ?? 'Trắng', const Color(0xFFEC4899)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Trải nghiệm xe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    car.description ?? 'Không có mô tả chi tiết cho xe này.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Reviews block synchronized with Frontend
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Khách hàng nói gì?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '4.9/5.0',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.black87,
                                  radius: 18,
                                  child: Text(
                                    'MN',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Minh Nguyen',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textColor),
                                    ),
                                    const Text(
                                      '2 ngày trước',
                                      style: TextStyle(fontSize: 11, color: AppTheme.subTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: List.generate(5, (_) => const Icon(Icons.star, color: Colors.amber, size: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Một trải nghiệm thực sự đẳng cấp. Xe mới, sạch và cảm giác lái rất phấn khích.',
                          style: TextStyle(fontSize: 13, color: AppTheme.subTextColor, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom floating bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          border: Border(top: BorderSide(color: Color(0xFFDEE2E6))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giá thuê tham khảo',
                  style: TextStyle(fontSize: 12, color: AppTheme.subTextColor),
                ),
                Text(
                  '${car.pricePerDay.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/ngày',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: car.carStatus == 'AVAILABLE'
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(car: car),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: car.carStatus == 'AVAILABLE'
                      ? AppTheme.secondaryColor
                      : Colors.black26,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  car.carStatus == 'AVAILABLE' ? 'ĐẶT XE NGAY' : 'XE ĐÃ ĐƯỢC THUÊ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.subTextColor, letterSpacing: 1.0),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textColor),
          ),
        ],
      ),
    );
  }
}
