import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _identifyIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _agreeToTerms = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản dịch vụ.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      identifyId: _identifyIdController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Bạn có thể đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thất bại. Tên đăng nhập hoặc email đã tồn tại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Left Panel: Brand image (Visible only on Desktop)
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=800',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.4),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tham gia Cộng đồng\nDi động Đẳng cấp.',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Khám phá tương lai của dịch vụ thuê xe với trải nghiệm cá nhân hóa và đội xe đẳng cấp nhất thế giới.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                radius: 20,
                                child: Icon(Icons.shield, color: Colors.white),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ĐƯỢC TIN DÙNG BỞI 50,000+',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Thành viên Premium trên toàn cầu',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Right Panel: Form
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Tạo tài khoản mới',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nâng tầm hành trình của bạn cùng EliteDrive ngay hôm nay.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subTextColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Inputs
                        TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryColor),
                            hintText: 'Nguyễn Văn A',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                        ),
                        const SizedBox(height: 16),

                        // Email & Phone Row
                        _buildResponsiveRow(
                          isDesktop: isDesktop,
                          child1: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ Email',
                              prefixIcon: Icon(Icons.mail_outline, color: AppTheme.primaryColor),
                              hintText: 'email@vi-du.com',
                            ),
                            validator: (val) => val == null || !val.contains('@') ? 'Vui lòng nhập email hợp lệ' : null,
                          ),
                          child2: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                              hintText: '090 123 4567',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Username & CCCD
                        _buildResponsiveRow(
                          isDesktop: isDesktop,
                          child1: TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Tên đăng nhập',
                              prefixIcon: Icon(Icons.account_circle_outlined, color: AppTheme.primaryColor),
                              hintText: 'user123',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                          ),
                          child2: TextFormField(
                            controller: _identifyIdController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Số CCCD',
                              prefixIcon: Icon(Icons.assignment_ind_outlined, color: AppTheme.primaryColor),
                              hintText: '0123456789',
                            ),
                            validator: (val) => val == null || val.trim().length < 9 ? 'CCCD tối thiểu 9 số' : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ thường trú',
                            prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                            hintText: '123 Đường, Quận, Thành phố',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password & Confirm Password Row
                        _buildResponsiveRow(
                          isDesktop: isDesktop,
                          child1: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                              hintText: '••••••••',
                            ),
                            validator: (val) => val == null || val.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                          ),
                          child2: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.black87),
                            decoration: const InputDecoration(
                              labelText: 'Xác nhận mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                              hintText: '••••••••',
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Vui lòng xác nhận mật khẩu' : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms and Conditions check
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) {
                                setState(() {
                                  _agreeToTerms = val ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Tôi đồng ý với Điều khoản dịch vụ',
                                style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              )
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('ĐĂNG KÝ NGAY'),
                              ),
                        const SizedBox(height: 24),

                        // OR divider
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFDEE2E6))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'HOẶC ĐĂNG KÝ BẰNG',
                                style: TextStyle(fontSize: 9, color: AppTheme.subTextColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFDEE2E6))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google oauth button
                        OutlinedButton(
                          onPressed: () async {
                            final currentUri = Uri.base;
                            final portStr = currentUri.port != 0 && currentUri.port != 80 && currentUri.port != 443 
                                ? ':${currentUri.port}' 
                                : '';
                            final redirectUrl = '${currentUri.scheme}://${currentUri.host}$portStr';
                            final googleAuthUrl = 'http://localhost:8080/oauth2/authorization/google?redirect_uri=$redirectUrl';
                            
                            final uri = Uri.parse(googleAuthUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.platformDefault);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFDEE2E6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4285F4),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tiếp tục với Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Sign in redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(color: Colors.black54),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Đăng nhập ngay',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isDesktop,
    required Widget child1,
    required Widget child2,
  }) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 16),
          Expanded(child: child2),
        ],
      );
    } else {
      return Column(
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    }
  }
}
