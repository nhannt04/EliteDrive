import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/customer_provider.dart';
import '../models/rental.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../fleet/screens/vehicle_detail_screen.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  String _selectedStatus = 'ALL';

  final List<Map<String, String>> _statusFilters = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING', 'label': 'Chờ xác nhận'},
    {'key': 'CONFIRMED', 'label': 'Đã xác nhận'},
    {'key': 'RENTING', 'label': 'Đang di chuyển'},
    {'key': 'COMPLETED', 'label': 'Hoàn thành'},
    {'key': 'CANCELLED', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRentals();
    });
  }

  void _loadRentals() {
    context.read<CustomerProvider>().fetchMyRentals(status: _selectedStatus);
  }

  void _handlePayment(Rental rental) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<CustomerProvider>();
    final checkoutUrl = await provider.createPayOSLink(rental.rentalId);

    if (checkoutUrl != null) {
      final uri = Uri.parse(checkoutUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          _showPaymentCheckDialog(rental.rentalId);
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết thanh toán.')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tạo link thanh toán thất bại.')),
      );
    }
  }

  void _showPaymentCheckDialog(int rentalId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool checking = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Đang tiến hành thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vui lòng hoàn tất thanh toán trên cổng PayOS.'),
                  const SizedBox(height: 20),
                  if (checking)
                    const CircularProgressIndicator(color: AppTheme.primaryColor)
                  else
                    const Icon(Icons.payment, size: 50, color: AppTheme.primaryColor),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: checking ? null : () => Navigator.pop(context),
                  child: const Text('Đóng', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: checking
                      ? null
                      : () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final customerProvider = context.read<CustomerProvider>();
                          final navigator = Navigator.of(context);

                          setStateDialog(() => checking = true);
                          final success = await customerProvider.confirmPaymentStatus(rentalId);
                          setStateDialog(() => checking = false);

                          if (!context.mounted) return;
                          navigator.pop(); // Close dialog
                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Thanh toán thành công! Trạng thái đơn đã cập nhật.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadRentals();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Giao dịch chưa hoàn tất hoặc thất bại.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('XÁC NHẬN ĐÃ THANH TOÁN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(Rental rental) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool loading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Xác nhận hủy đơn',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn có chắc chắn muốn hủy đơn đặt xe #${rental.rentalId}?',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Vui lòng nhập lý do hủy đơn...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text('ĐÓNG', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) return;

                          setStateDialog(() => loading = true);
                          final success = await context.read<CustomerProvider>().cancelRental(rental.rentalId, reason);
                          setStateDialog(() => loading = false);

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hủy đơn đặt xe thành công!'), backgroundColor: Colors.green),
                              );
                              _loadRentals();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không thể hủy đơn đặt xe này.'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('XÁC NHẬN HỦY'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptSheet(Rental rental) {
    final subtotal = rental.totalPrice / 1.1;
    final tax = rental.totalPrice - subtotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EliteDrive',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          Text(
                            'CHI TIẾT DỊCH VỤ THUÊ XE',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Mã đơn: #RD-${rental.rentalId}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (rental.status == 'CANCELLED') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đơn đặt xe đã bị hủy',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'THÔNG TIN KHÁCH HÀNG',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rental.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    rental.customerEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 14),
                      SizedBox(width: 6),
                      Text('Điểm nhận: Showroom EliteDrive Hà Nội', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'THÔNG TIN THỜI GIAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${rental.startDate}  —  ${rental.endDate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'CHI TIẾT THANH TOÁN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rental.carName ?? 'Hạng mục phương tiện',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${subtotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Biển số: ${rental.brand ?? 'Premium'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              '${rental.seats ?? 5} Chỗ',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('${subtotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('VAT (10%):', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('${tax.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TỔNG CỘNG:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                            ),
                            Text(
                              '${rental.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ĐÓNG HÓA ĐƠN'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFF0EA5E9); // sky blue
      case 'CONFIRMED':
        return const Color(0xFF22C55E); // green
      case 'RENTING':
        return const Color(0xFFF59E0B); // amber/orange
      case 'COMPLETED':
        return const Color(0xFF10B981); // emerald green
      case 'CANCELLED':
        return const Color(0xFF64748B); // slate grey
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'RENTING':
        return 'Đang di chuyển';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch sử thuê xe',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Quản lý và xem lại những hành trình của bạn.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Tabs Bar — underline style matching frontend
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = _selectedStatus == filter['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = filter['key'] ?? 'ALL');
                      _loadRentals();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: isSelected
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFF0EA5E9), width: 3),
                              )
                            : null,
                      ),
                      child: Text(
                        filter['label'] ?? '',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                : provider.errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider.errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRentals,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : provider.rentals.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Chưa có chuyến đi nào',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hãy bắt đầu hành trình đầu tiên của bạn cùng EliteDrive.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: provider.rentals.length,
                            itemBuilder: (context, index) {
                              try {
                                final rental = provider.rentals[index];
                                final statusColor = _getStatusColor(rental.status);
                                final statusText = _getStatusText(rental.status);

                                return _buildRentalCard(rental, statusColor, statusText);
                              } catch (e, stack) {
                                return Card(
                                  color: Colors.red.shade50,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Lỗi dựng thẻ xe:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                        const SizedBox(height: 8),
                                        Text(e.toString(), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(stack.toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Rental rental, Color statusColor, String statusText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: car info + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 90,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: rental.thumbnailUrl != null && rental.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          ApiClient.resolveImageUrl(rental.thumbnailUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.directions_car, size: 36, color: Color(0xFF94A3B8)),
                        )
                      : const Icon(Icons.directions_car, size: 36, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 14),
                // Car name + brand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (rental.brand ?? 'LUXURY CLASS').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rental.carName ?? 'Thông tin xe',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info grid: Ngày nhận / Ngày trả / Địa điểm / Sức chứa
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                _infoCell('NGÀY NHẬN', rental.startDate ?? '—', border: true),
                _infoCell('NGÀY TRẢ', rental.endDate ?? '—', border: true),
                _infoCell('ĐỊA ĐIỂM', 'Hà Nội, VN', border: true),
                _infoCell('SỨC CHỨA', '${rental.seats ?? 5} Chỗ', border: false),
              ],
            ),
          ),

          // Price + Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      rental.totalPrice.toInt().toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]}.',
                          ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VND Tổng cộng',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (rental.status == 'PENDING') ...[
                      _outlineButton('Hủy đơn', Colors.redAccent, () => _showCancelDialog(rental)),
                      _filledButton('Thanh toán', const Color(0xFF22C55E), () => _handlePayment(rental)),
                    ],
                    if (rental.status == 'COMPLETED' || rental.status == 'CANCELLED')
                      _filledButton('Đặt lại', const Color(0xFF0EA5E9), () {
                        if (rental.carId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailScreen(carId: rental.carId!),
                            ),
                          );
                        }
                      }),
                    _outlineButton('Chi tiết', const Color(0xFF0F172A), () => _showReceiptSheet(rental)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value, {required bool border}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: border
            ? const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _filledButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
