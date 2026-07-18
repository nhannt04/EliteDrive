import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fleet_provider.dart';
import '../models/car.dart';
import 'booking_success_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class BookingScreen extends StatefulWidget {
  final Car car;
  const BookingScreen({super.key, required this.car});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _locationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default date range initialized to tomorrow -> tomorrow + 2 days (matches frontend)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final dayAfterTomorrow = tomorrow.add(const Duration(days: 2));
    _endDate = DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day);
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  void _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 2)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời gian nhận và trả xe.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<FleetProvider>();

    final locationStr = _locationController.text.trim();
    final finalNotes = "Địa điểm nhận: ${locationStr.isEmpty ? 'Văn phòng EliteDrive' : locationStr}. Thanh toán: CARD";

    final success = await provider.createBooking(
      widget.car.carId,
      _startDate!,
      _endDate!,
      finalNotes,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        final days = _endDate!.difference(_startDate!).inDays <= 0 ? 1 : _endDate!.difference(_startDate!).inDays;
        final total = widget.car.pricePerDay * days;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              car: widget.car,
              startDate: _startDate!,
              endDate: _endDate!,
              totalPrice: total,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt xe thất bại. Xe có thể đã được đặt trong thời gian này.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int days = 0;
    double total = 0.0;
    double subtotal = 0.0;
    double tax = 0.0;

    if (_startDate != null && _endDate != null) {
      days = _endDate!.difference(_startDate!).inDays;
      if (days <= 0) days = 1;
      total = widget.car.pricePerDay * days;
      subtotal = (total / 1.1).roundToDouble();
      tax = total - subtotal;
    }

    String formatDate(DateTime? date) {
      if (date == null) return '--/--/----';
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    String formatMoney(double amount) {
      return amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hoàn tất đặt xe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hoàn tất đặt xe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kiểm tra thông tin và xác nhận hành trình của bạn.',
              style: TextStyle(fontSize: 13, color: AppTheme.subTextColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Card 1: Vehicle Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.car.thumbnailUrl != null && widget.car.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            ApiClient.resolveImageUrl(widget.car.thumbnailUrl),
                            width: 110,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 50, color: AppTheme.subTextColor),
                          )
                        : const Icon(Icons.directions_car, size: 50, color: AppTheme.subTextColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'HẠNG XE CAO CẤP',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.car.carName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.settings, size: 12, color: AppTheme.subTextColor),
                                const SizedBox(width: 2),
                                Text(widget.car.transmission == 'AUTOMATIC' ? 'Tự động' : 'Số sàn', style: const TextStyle(fontSize: 11, color: AppTheme.subTextColor)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people, size: 12, color: AppTheme.subTextColor),
                                const SizedBox(width: 2),
                                Text('${widget.car.seats} chỗ', style: const TextStyle(fontSize: 11, color: AppTheme.subTextColor)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_gas_station, size: 12, color: AppTheme.subTextColor),
                                const SizedBox(width: 2),
                                Text(widget.car.fuelType == 'GASOLINE' ? 'Xăng' : 'Dầu', style: const TextStyle(fontSize: 11, color: AppTheme.subTextColor)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Bảo hiểm toàn diện', style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Hỗ trợ 24/7', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Thời gian thuê
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: AppTheme.textColor),
                      SizedBox(width: 8),
                      Text(
                        'Thời gian thuê',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NGÀY NHẬN XE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.subTextColor),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectStartDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(formatDate(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NGÀY TRẢ XE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.subTextColor),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectEndDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(formatDate(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600),
                              children: [
                                const TextSpan(text: 'Tổng thời gian: '),
                                TextSpan(
                                  text: '$days ngày',
                                  style: TextStyle(fontSize: 13, color: Colors.blue[900], fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: Địa điểm nhận xe
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textColor),
                            SizedBox(width: 8),
                            Text(
                              'Địa điểm nhận xe',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HỖ TRỢ GIAO TẬN NƠI',
                          style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'VD: 123 Đường ABC, Quận Cầu Giấy, Hà Nội...',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 4: Chi tiết thanh toán
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chi tiết thanh toán',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentRow(
                    'Giá thuê (${formatMoney(widget.car.pricePerDay)} x $days ngày)',
                    '${formatMoney(subtotal)} VND',
                    isBoldVal: true,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentRow(
                    'Bảo hiểm & Phí dịch vụ',
                    '0 VND',
                    isGreenVal: true,
                    isBoldVal: true,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentRow(
                    'Thuế VAT (10%)',
                    '${formatMoney(tax)} VND',
                    isBoldVal: true,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG CỘNG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.subTextColor, letterSpacing: 1.0),
                      ),
                      Text(
                        '${formatMoney(total)} VND',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF073763), // Dark blue like React button
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: _submit,
                            child: const Text(
                              'XÁC NHẬN ĐẶT XE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
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
  }

  Widget _buildPaymentRow(String label, String value, {bool isGreenVal = false, bool isBoldVal = false}) {
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
            fontWeight: isBoldVal ? FontWeight.bold : FontWeight.normal,
            color: isGreenVal ? Colors.green : AppTheme.textColor,
          ),
        ),
      ],
    );
  }
}
