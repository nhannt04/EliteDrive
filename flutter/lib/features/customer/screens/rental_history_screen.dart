import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/customer_provider.dart';
import '../models/rental.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchMyRentals();
    });
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
        
        // Show status validation dialog
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
              backgroundColor: AppTheme.cardColor,
              title: const Text('Đang tiến hành thanh toán'),
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
                  onPressed: checking
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Đóng'),
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
                            customerProvider.fetchMyRentals();
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'RENTING':
        return Colors.green;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'RENTING':
        return 'Đang thuê';
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
      appBar: AppBar(
        title: const Text('LỊCH SỬ THUÊ XE'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : provider.errorMessage.isNotEmpty
              ? Center(child: Text(provider.errorMessage))
              : provider.rentals.isEmpty
                  ? const Center(child: Text('Bạn chưa có chuyến đi nào.'))
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchMyRentals(),
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.rentals.length,
                        itemBuilder: (context, index) {
                          final rental = provider.rentals[index];
                          final statusColor = _getStatusColor(rental.status);
                          final statusText = _getStatusText(rental.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppTheme.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFDEE2E6)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Đơn hàng #${rental.rentalId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Color(0xFFDEE2E6), height: 24),
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: rental.thumbnailUrl != null && rental.thumbnailUrl!.isNotEmpty
                                            ? Image.network(
                                                ApiClient.resolveImageUrl(rental.thumbnailUrl),
                                                width: 80,
                                                height: 55,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40, color: AppTheme.subTextColor),
                                              )
                                            : const Icon(Icons.directions_car, size: 40, color: AppTheme.subTextColor),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rental.carName ?? 'Thuê xe ô tô',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                            ),
                                            Text(
                                              'Thời gian: ${rental.startDate} đến ${rental.endDate}',
                                              style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Color(0xFFDEE2E6), height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Tổng chi phí:',
                                        style: TextStyle(color: AppTheme.subTextColor),
                                      ),
                                      Text(
                                        '${rental.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (rental.status == 'PENDING') ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _handlePayment(rental),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'THANH TOÁN QUA PAYOS',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
