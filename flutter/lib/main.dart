import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'core/network/api_client.dart';
import 'features/fleet/providers/fleet_provider.dart';
import 'features/fleet/screens/vehicle_listing_screen.dart';
import 'features/customer/providers/customer_provider.dart';
import 'features/customer/screens/rental_history_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/change_password_screen.dart';
import 'features/admin/providers/admin_user_provider.dart';
import 'features/admin/screens/admin_user_list_screen.dart';
import 'features/admin/screens/admin_car_list_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FleetProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EliteDrive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final urlToken = Uri.base.queryParameters['token'];
      if (urlToken != null && urlToken.isNotEmpty) {
        await authProvider.loginWithToken(urlToken);
      } else {
        await authProvider.tryAutoLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Backend returns roles as list of strings like ["ROLE_ADMIN"]
    final isAdmin = auth.roles?.contains('ROLE_ADMIN') ?? false;

    final List<Widget> screens = [
      HomeScreen(onNavigateToTab: (index) {
        setState(() {
          _selectedIndex = index;
        });
      }),
      const VehicleListingScreen(),
      if (isAdmin) const AdminCarListScreen() else const RentalHistoryScreen(),
      if (isAdmin) const AdminUserListScreen(),
    ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = screens.length - 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ELITEDRIVE'),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.directions_car_filled, color: Colors.white, size: 28),
        ),
        actions: [
          if (auth.isAuthenticated)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  auth.logout();
                } else if (value == 'dashboard') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                }
              },
              offset: const Offset(0, 50),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiClient.resolveImageUrl(auth.avatarUrl))
                    : null,
                child: auth.avatarUrl == null || auth.avatarUrl!.isEmpty
                    ? const Icon(Icons.account_circle, color: Colors.white, size: 36)
                    : null,
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.fullName ?? auth.username ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAdmin ? 'Quản trị viên (Admin)' : 'Thành viên Premium',
                        style: const TextStyle(color: AppTheme.subTextColor, fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_outlined, size: 18, color: AppTheme.subTextColor),
                      SizedBox(width: 12),
                      Text('Hồ sơ của tôi', style: TextStyle(fontSize: 13, color: AppTheme.textColor)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.security_outlined, size: 18, color: AppTheme.subTextColor),
                      SizedBox(width: 12),
                      Text('Bảo mật', style: TextStyle(fontSize: 13, color: AppTheme.textColor)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.subTextColor,
        type: BottomNavigationBarType.fixed, // Needed for >3 items
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.car_rental),
            label: 'Thuê Xe',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_applications),
              label: 'Q.Lý Xe',
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'Người dùng',
            ),
        ],
      ),
    );
  }
}
