import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile_model.dart';
import '../../../core/network/api_client.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _identifyIdController;
  late TextEditingController _dobController;
  
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _identifyIdController = TextEditingController();
    _dobController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile().then((_) {
        _populateFields();
      });
    });
  }
  
  void _populateFields() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
      _addressController.text = profile.address ?? '';
      _identifyIdController.text = profile.identifyId ?? '';
      _dobController.text = profile.dateOfBirth ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _identifyIdController.dispose();
    _dobController.dispose();
    super.dispose();
  }
  
  void _toggleEdit() {
    if (_isEditing) {
      // Cancel edit, revert fields
      _populateFields();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentProfile = context.read<ProfileProvider>().profile;
    if (currentProfile == null) return;
    
    final updatedProfile = UserProfileModel(
      userId: currentProfile.userId,
      username: currentProfile.username,
      email: currentProfile.email,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      identifyId: _identifyIdController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      avatarUrl: currentProfile.avatarUrl,
      roles: currentProfile.roles,
      isEnabled: currentProfile.isEnabled,
      userType: currentProfile.userType,
    );
    
    final errorMessage = await context.read<ProfileProvider>().updateProfile(updatedProfile);
    
    if (mounted) {
      if (errorMessage == null) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _toggleEdit,
              tooltip: 'Chỉnh sửa hồ sơ',
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleEdit,
              tooltip: 'Hủy chỉnh sửa',
            )
        ],
      ),
      body: provider.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : profile == null
              ? const Center(child: Text('Không thể tải thông tin hồ sơ.'))
              : _buildBody(profile, provider.isLoading),
    );
  }
  
  Widget _buildBody(UserProfileModel profile, bool isLoading) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Background Gradient extension of AppBar
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative patterns
                    Positioned(
                      top: -20,
                      right: -40,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      left: -20,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar Area positioned to overlap
              Positioned(
                bottom: -64,
                child: _buildAvatarArea(profile),
              ),
            ],
          ),
          
          const SizedBox(height: 72), // Space for the overlapping avatar
          
          // Name and Email Display
          Text(
                  _isEditing ? _fullNameController.text : profile.fullName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!_isEditing && profile.roles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _getRoleDisplay(profile.roles),
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 32),
                
                // Form Fields or Display Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isEditing)
                            _buildEditForm(isLoading)
                          else
                            _buildDisplayCards(profile),
                            
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatarArea(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiClient.resolveImageUrl(profile.avatarUrl))
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: AppTheme.primaryLight)
                    : null,
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 4,
              right: 4,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đổi ảnh đại diện đang phát triển.')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisplayCards(UserProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          title: 'Thông tin liên hệ',
          icon: Icons.contact_mail_outlined,
          children: [
            _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', profile.phoneNumber ?? 'Chưa cập nhật'),
            const Divider(height: 1, indent: 40),
            _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', profile.address ?? 'Chưa cập nhật'),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          title: 'Thông tin định danh',
          icon: Icons.assignment_ind_outlined,
          children: [
            _buildInfoRow(Icons.credit_card_outlined, 'Số CCCD', profile.identifyId ?? 'Chưa cập nhật'),
            const Divider(height: 1, indent: 40),
            _buildInfoRow(Icons.cake_outlined, 'Ngày sinh', profile.dateOfBirth ?? 'Chưa cập nhật'),
          ],
        ),
        const SizedBox(height: 24),
        // Security Settings
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_outlined, color: AppTheme.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bảo mật & Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Cập nhật mật khẩu để bảo vệ tài khoản', style: TextStyle(fontSize: 13, color: AppTheme.subTextColor)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.subTextColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, color: AppTheme.textColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cập nhật thông tin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.trim().isEmpty ? 'Bắt buộc nhập' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _dobController,
                label: 'Ngày sinh (YYYY-MM-DD)',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _identifyIdController,
                label: 'Số CCCD',
                icon: Icons.assignment_ind_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ thường trú',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _toggleEdit,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text('HỦY BỎ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        fillColor: Colors.grey[50],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
    );
  }
  
  String _getRoleDisplay(List<String> roles) {
    if (roles.contains('ROLE_ADMIN')) return 'Quản trị viên (Admin)';
    if (roles.contains('ROLE_STAFF')) return 'Nhân viên (Staff)';
    return 'Thành viên (Customer)';
  }
}
