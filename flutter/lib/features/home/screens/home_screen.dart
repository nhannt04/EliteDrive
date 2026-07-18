import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../fleet/providers/fleet_provider.dart';
import '../../fleet/screens/vehicle_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const HomeScreen({super.key, required this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchCars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleetProvider = context.watch<FleetProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO SECTION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Thuê xe nhanh chóng, Lăn bánh tức thì',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chỉ với vài cú click, sở hữu ngay chiếc xe ưng ý cho chuyến đi của bạn. Thủ tục đơn giản, minh bạch và nhận xe trong tích tắc.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Search Form Card
                  Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Địa điểm nhận xe / Từ khóa',
                              prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
                              fillColor: Color(0xFFF8F9FA),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final keyword = _searchController.text.trim();
                              fleetProvider.fetchCars(keyword: keyword);
                              widget.onNavigateToTab(1); // Navigate to Fleet List Tab
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('TÌM XE NGAY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1.5 CATEGORIES SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Danh Mục Xe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Khám phá lựa chọn được tuyển chọn của chúng tôi cho mọi nhu cầu di chuyển',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryCard(
                    'Sedan Hạng Sang',
                    'Sự sang trọng kết hợp với hiệu suất dành cho giới chuyên gia',
                    'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Xe SUV',
                          'Rộng rãi & Mạnh mẽ',
                          'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=800',
                          height: 150,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          'Đội Xe Điện',
                          'Thân thiện với môi trường',
                          'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?auto=format&fit=crop&q=80&w=800',
                          height: 150,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. FEATURED FLEET
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đội xe nổi bật',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Những mẫu xe cao cấp nhất',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.subTextColor,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateToTab(1),
                        child: const Row(
                          children: [
                            Text(
                              'XEM TẤT CẢ',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryColor),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  fleetProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : fleetProvider.cars.isEmpty
                          ? const Center(child: Text('Chưa có xe nổi bật nào.'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: fleetProvider.cars.length > 3 ? 3 : fleetProvider.cars.length,
                              itemBuilder: (context, index) {
                                final car = fleetProvider.cars[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VehicleDetailScreen(carId: car.carId),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    color: AppTheme.cardColor,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFDEE2E6)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: car.thumbnailUrl != null && car.thumbnailUrl!.isNotEmpty
                                                  ? Image.network(
                                                      ApiClient.resolveImageUrl(car.thumbnailUrl),
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        height: 180,
                                                        color: const Color(0xFFE9ECEF),
                                                        child: const Icon(Icons.directions_car, size: 60),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 180,
                                                      color: const Color(0xFFE9ECEF),
                                                      child: const Icon(Icons.directions_car, size: 60),
                                                    ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondaryColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'THUÊ NHIỀU',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    car.brand.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.secondaryColor,
                                                    ),
                                                  ),
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                                      Text(
                                                        ' 4.9',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                car.carName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${car.seats} Chỗ • ${car.transmission == 'AUTOMATIC' ? 'Tự động' : 'Số sàn'} • Xăng',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.subTextColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${car.pricePerDay.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/ngày',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),

            // 3. TESTIMONIALS SECTION
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'Được Tin Tưởng Bởi Chuyên Gia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chất lượng dịch vụ xuất sắc từ EliteDrive',
                    style: TextStyle(fontSize: 12, color: AppTheme.subTextColor),
                  ),
                  const SizedBox(height: 24),
                  _buildTestimonialCard(
                    'Marcus Henderson',
                    'Phó Chủ tịch Doanh nghiệp',
                    'Mức độ dịch vụ tại EliteDrive là vô đối. Quy trình nhận xe diễn ra liền mạch và phương tiện luôn trong tình trạng như mới từ showroom.',
                  ),
                  _buildTestimonialCard(
                    'Elena Rodriguez',
                    'Người sáng lập Tech',
                    'Tôi đặc biệt chỉ sử dụng đội xe điện của họ khi di chuyển trong thành phố. Sự hỗ trợ sạc điện mà họ cung cấp giúp trải nghiệm trở nên hoàn toàn thoải mái.',
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, String imageUrl, {double height = 200}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(String name, String role, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$text"',
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                radius: 18,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textColor),
                  ),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 11, color: AppTheme.subTextColor),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
