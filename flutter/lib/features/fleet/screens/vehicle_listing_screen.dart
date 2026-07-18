import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fleet_provider.dart';
import 'vehicle_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class VehicleListingScreen extends StatefulWidget {
  const VehicleListingScreen({super.key});

  @override
  State<VehicleListingScreen> createState() => _VehicleListingScreenState();
}

class _VehicleListingScreenState extends State<VehicleListingScreen> {
  final _searchController = TextEditingController();
  String _sort = 'pricePerDay,asc';

  List<String> _selectedBrands = [];
  int? _selectedSeats;
  double _maxPrice = 5000000;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchCars();
    });
  }

  void _onSearch() {
    context.read<FleetProvider>().fetchCars(
          keyword: _searchController.text.trim(),
          sort: _sort,
          brand: _selectedBrands.isNotEmpty ? _selectedBrands.join(',') : null,
          seats: _selectedSeats,
          maxPrice: _maxPrice,
          startDate: _startDate != null ? _startDate!.toIso8601String().substring(0, 10) : null,
          endDate: _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : null,
        );
  }

  void _showFilterBottomSheet() {
    List<String> tempSelectedBrands = List.from(_selectedBrands);
    int? tempSelectedSeats = _selectedSeats;
    double tempMaxPrice = _maxPrice;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final brands = ['Toyota', 'Honda', 'VinFast', 'Hyundai', 'Ford', 'Mercedes', 'BMW', 'Audi'];
            final seatOptions = [4, 5, 7];

            String formatDate(DateTime? date) {
              if (date == null) return 'Chọn ngày';
              return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            }

            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                bottom: bottomPadding < 0 ? 0 : bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bộ lọc tìm kiếm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedBrands.clear();
                                tempSelectedSeats = null;
                                tempMaxPrice = 5000000;
                                tempStartDate = null;
                                tempEndDate = null;
                              });
                            },
                            child: const Text(
                              'Xóa hết',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THỜI GIAN CHUYẾN ĐI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: tempStartDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          tempStartDate = picked;
                                          if (tempEndDate != null && tempEndDate!.isBefore(picked)) {
                                            tempEndDate = null;
                                          }
                                        });
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        const Text('Nhận xe', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatDate(tempStartDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: tempEndDate ?? (tempStartDate ?? DateTime.now()),
                                        firstDate: tempStartDate ?? DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          tempEndDate = picked;
                                        });
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        const Text('Trả xe', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatDate(tempEndDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'SỨC CHỨA (SỐ GHẾ)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: seatOptions.map((seats) {
                                final isSelected = tempSelectedSeats == seats;
                                return ChoiceChip(
                                  label: Text('$seats chỗ'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempSelectedSeats = selected ? seats : null;
                                    });
                                  },
                                  selectedColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'GIÁ TỐI ĐA / NGÀY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  '${tempMaxPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              min: 500000,
                              max: 10000000,
                              divisions: 95,
                              value: tempMaxPrice,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) {
                                setModalState(() {
                                  tempMaxPrice = val;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('500K', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                Text('10M+', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'THƯƠNG HIỆU XE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: brands.map((brand) {
                                final isSelected = tempSelectedBrands.contains(brand);
                                return FilterChip(
                                  label: Text(brand),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        tempSelectedBrands.add(brand);
                                      } else {
                                        tempSelectedBrands.remove(brand);
                                      }
                                    });
                                  },
                                  selectedColor: AppTheme.primaryColor,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedBrands = tempSelectedBrands;
                                  _selectedSeats = tempSelectedSeats;
                                  _maxPrice = tempMaxPrice;
                                  _startDate = tempStartDate;
                                  _endDate = tempEndDate;
                                });
                                Navigator.pop(context);
                                _onSearch();
                              },
                              child: const Text(
                                'ÁP DỤNG BỘ LỌC',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐỘI XE ELITEDRIVE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() => _sort = value);
              _onSearch();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pricePerDay,asc',
                child: Text('Giá: Thấp đến Cao'),
              ),
              const PopupMenuItem(
                value: 'pricePerDay,desc',
                child: Text('Giá: Cao đến Thấp'),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm xe...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : provider.errorMessage.isNotEmpty
                    ? Center(child: Text(provider.errorMessage))
                    : provider.cars.isEmpty
                        ? const Center(child: Text('Không tìm thấy xe nào.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: provider.cars.length,
                            itemBuilder: (context, index) {
                              final car = provider.cars[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailScreen(carId: car.carId),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFDEE2E6)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: car.thumbnailUrl != null && car.thumbnailUrl!.isNotEmpty
                                              ? Image.network(
                                                  ApiClient.resolveImageUrl(car.thumbnailUrl!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: const Color(0xFFE9ECEF),
                                                    child: const Icon(Icons.directions_car, size: 50, color: AppTheme.subTextColor),
                                                  ),
                                                )
                                              : Container(
                                                  color: const Color(0xFFE9ECEF),
                                                  child: const Icon(Icons.directions_car, size: 50, color: AppTheme.subTextColor),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              car.brand.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              car.carName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${car.seats} Chỗ',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.subTextColor,
                                                  ),
                                                ),
                                                Text(
                                                  car.transmission == 'AUTOMATIC' ? 'Tự động' : 'Số sàn',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.subTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(color: Color(0xFFDEE2E6)),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  'Giá/Ngày',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme.subTextColor,
                                                  ),
                                                ),
                                                Text(
                                                  '${car.pricePerDay.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.secondaryColor,
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
          ),
        ],
      ),
    );
  }
}
