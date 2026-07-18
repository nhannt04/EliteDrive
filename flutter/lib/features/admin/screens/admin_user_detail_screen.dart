import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/models/user_profile_model.dart';
import '../../../core/network/api_client.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final UserProfileModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isAdminRole = user.roles.contains('ROLE_ADMIN');
    final isStaffRole = user.roles.contains('ROLE_STAFF');
    final roleColor = isAdminRole ? Colors.orange : (isStaffRole ? Colors.purple : Colors.blue);
    final roleName = isAdminRole ? 'ADMIN' : (isStaffRole ? 'STAFF' : 'CUSTOMER');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Chi tiết Người dùng'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textColor,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: roleColor.withOpacity(0.1),
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(ApiClient.resolveImageUrl(user.avatarUrl!))
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Icon(Icons.person, size: 50, color: roleColor)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      roleName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: user.isEnabled ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        user.isEnabled ? Icons.check_circle_outline : Icons.block,
                        color: user.isEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái tài khoản',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.isEnabled ? 'Đang hoạt động' : 'Đang bị khóa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: user.isEnabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detailed Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin chi tiết',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.account_circle_outlined, 'Tên đăng nhập (Username)', user.username),
                    _buildDivider(),
                    _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                    _buildDivider(),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', user.phoneNumber ?? 'Chưa cập nhật'),
                    _buildDivider(),
                    _buildInfoRow(Icons.cake_outlined, 'Ngày sinh', user.dateOfBirth ?? 'Chưa cập nhật'),
                    _buildDivider(),
                    _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', user.address ?? 'Chưa cập nhật'),
                    _buildDivider(),
                    _buildInfoRow(Icons.badge_outlined, 'CCCD / CMND', user.identifyId ?? 'Chưa cập nhật'),
                    _buildDivider(),
                    _buildInfoRow(Icons.card_membership_outlined, 'GPLX (Bằng lái xe)', user.driverLicenceId ?? 'Chưa cập nhật'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.grey[100],
    );
  }
}
