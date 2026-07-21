import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/models/rental.dart';
import '../providers/staff_rental_provider.dart';

class RentalManagementScreen extends StatefulWidget {
  const RentalManagementScreen({super.key});

  @override
  State<RentalManagementScreen> createState() => _RentalManagementScreenState();
}

class _RentalManagementScreenState extends State<RentalManagementScreen> {
  String _selectedStatus = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  final List<Map<String, String>> _statusFilters = [
    {'key': 'ALL', 'label': 'Tất cả'},
    {'key': 'PENDING', 'label': 'Chờ duyệt'},
    {'key': 'CONFIRMED', 'label': 'Đã duyệt'},
    {'key': 'RENTING', 'label': 'Đang thuê'},
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRentals() {
    context.read<StaffRentalProvider>().fetchAllRentals(
          status: _selectedStatus,
          keyword: _keyword,
        );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _keyword = value;
    });
    _loadRentals();
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
                'Từ chối / Hủy đơn',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vui lòng nhập lý do từ chối hoặc hủy đơn đặt xe #${rental.rentalId}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập lý do hủy đơn...',
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
                          final success = await context.read<StaffRentalProvider>().updateRentalStatus(
                                rental.rentalId,
                                'CANCELLED',
                                cancelReason: reason,
                              );
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

  void _confirmStatusUpdate(Rental rental, String nextStatus, String title, String message, Color confirmColor) {
    showDialog(
      context: context,
      builder: (context) {
        bool loading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: confirmColor),
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text('ĐÓNG', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setStateDialog(() => loading = true);
                          final success = await context.read<StaffRentalProvider>().updateRentalStatus(rental.rentalId, nextStatus);
                          setStateDialog(() => loading = false);

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cập nhật trạng thái thành công!'), backgroundColor: Colors.green),
                              );
                              _loadRentals();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không thể cập nhật trạng thái.'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('XÁC NHẬN'),
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
                            'CHI TIẾT ĐƠN HÀNG VẬN HÀNH',
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
                    child: const Text('ĐÓNG CHI TIẾT'),
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
        return 'Chờ duyệt';
      case 'CONFIRMED':
        return 'Đã duyệt';
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

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    val,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffRentalProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    // Check if the current user is Staff vs Admin
    final isStaff = authProvider.roles.contains('ROLE_STAFF');
    final isAdmin = authProvider.roles.contains('ROLE_ADMIN');
    
    // Admin only has read-only access
    final canUpdateStatus = isStaff && !isAdmin;

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
              'Quản lý thuê xe',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Giám sát và vận hành hoạt động đội xe thời gian thực.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadRentals,
          ),
        ],
        toolbarHeight: 70,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _buildStatCard('TỔNG ĐƠN', '${provider.totalCount}', Icons.assessment, const Color(0xFF3B82F6)),
                _buildStatCard('CHỜ DUYỆT', '${provider.pendingCount}', Icons.hourglass_empty, const Color(0xFFF59E0B)),
                _buildStatCard('ĐANG THUÊ', '${provider.rentingCount}', Icons.directions_car, const Color(0xFF10B981)),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng, xe...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filter Tabs Bar
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

          // Rental List
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
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Không tìm thấy đơn thuê',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: provider.rentals.length,
                            itemBuilder: (context, index) {
                              final rental = provider.rentals[index];
                              final statusColor = _getStatusColor(rental.status);
                              final statusText = _getStatusText(rental.status);

                              return _buildRentalCard(rental, statusColor, statusText, canUpdateStatus);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Rental rental, Color statusColor, String statusText, bool canUpdateStatus) {
    final s = rental.status.toUpperCase();

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
          // Top row: Car info + Status badge
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
                // Car details & Customer info
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
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Customer name indicator
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rental.customerName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

          // Info grid: Ngày nhận / Ngày trả / Sức chứa
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
                _infoCell('NGÀY NHẬN', rental.startDate, border: true),
                _infoCell('NGÀY TRẢ', rental.endDate, border: true),
                _infoCell('SỨC CHỨA', '${rental.seats ?? 5} Chỗ', border: false),
              ],
            ),
          ),

          // Price + Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'đ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Buttons
                Wrap(
                  spacing: 6,
                  children: [
                    if (canUpdateStatus && s == 'PENDING') ...[
                      _actionButton('DUYỆT', const Color(0xFF22C55E), () {
                        _confirmStatusUpdate(
                          rental,
                          'CONFIRMED',
                          'Phê duyệt đơn thuê',
                          'Xác nhận phê duyệt đơn đặt xe này và thông báo cho khách hàng?',
                          const Color(0xFF22C55E),
                        );
                      }),
                      _actionButton('HỦY', Colors.redAccent, () {
                        _showCancelDialog(rental);
                      }),
                    ],
                    if (canUpdateStatus && s == 'CONFIRMED') ...[
                      _actionButton('GIAO XE', const Color(0xFFF59E0B), () {
                        _confirmStatusUpdate(
                          rental,
                          'RENTING',
                          'Bắt đầu chuyến đi',
                          'Xác nhận đã giao xe cho khách hàng và bắt đầu tính thời gian thuê?',
                          const Color(0xFFF59E0B),
                        );
                      }),
                    ],
                    if (canUpdateStatus && s == 'RENTING') ...[
                      _actionButton('NHẬN XE', const Color(0xFF10B981), () {
                        _confirmStatusUpdate(
                          rental,
                          'COMPLETED',
                          'Hoàn thành đơn thuê',
                          'Xác nhận đã nhận lại xe và khách hàng đã thanh toán đầy đủ?',
                          const Color(0xFF10B981),
                        );
                      }),
                    ],
                    _outlineButton('Chi tiết', const Color(0xFF0F172A), () {
                      _showReceiptSheet(rental);
                    }),
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

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _outlineButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
