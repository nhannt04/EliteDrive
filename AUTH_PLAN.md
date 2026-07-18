# Kế hoạch phát triển Module Auth trên Flutter cho EliteDrive

Dựa trên phân tích mã nguồn từ Backend (Spring Boot), Frontend (React/Vite), và ứng dụng Flutter hiện tại, dưới đây là bản đánh giá chi tiết về chức năng Auth và kế hoạch hoàn thiện UI trên Flutter.

## 1. Phân tích chức năng Module Auth hiện tại

### 1.1. Backend (Spring Boot)
Backend đã cung cấp đầy đủ các API RESTful cho Authentication tại `AuthController.java` và các Service liên quan:
- **Đăng nhập / Đăng ký**: `/api/auth/login`, `/api/auth/register` (Sử dụng JWT).
- **Quản lý mật khẩu**: 
  - `/api/auth/forgot-password`: Gửi OTP qua email.
  - `/api/auth/verify-otp`: Xác thực mã OTP.
  - `/api/auth/reset-password`: Đặt lại mật khẩu bằng token.
  - `/api/auth/change-password`: Đổi mật khẩu cho người dùng đang đăng nhập.
- **Xác thực Social (OAuth2)**: Hỗ trợ Google Login (`/oauth2/authorization/google`), xử lý token sau khi đăng nhập thành công qua Cookie và Redirect.
- **Thông tin tài khoản**: `/api/auth/me` để lấy thông tin chi tiết (FullName, Avatar, Roles), `/api/auth/logout` để đăng xuất.

### 1.2. Frontend Web (React / Vite)
Web Frontend đã tích hợp gần như hoàn chỉnh các luồng Auth:
- Các components đầy đủ: `Login.jsx`, `Register.jsx`, `ForgotPassword.jsx`, `ResetPassword.jsx`, `ChangePasswordModal.jsx`.
- Xử lý mượt mà luồng OAuth2 thông qua `OAuth2RedirectHandler.jsx`.
- Lưu trữ JWT và quản lý State bằng `AuthContext.jsx`.

### 1.3. Ứng dụng Flutter
Hiện tại ứng dụng Flutter mới chỉ triển khai một phần của Auth:
- Đã có `auth_provider.dart` để quản lý state cơ bản (Login, Register).
- UI đã có `login_screen.dart` (có nút đăng nhập Google nhưng xử lý redirect url cho web đang cần hoàn thiện thêm) và `register_screen.dart`.
- **Thiếu sót**: Chưa có UI và logic cho luồng Quên mật khẩu, Xác thực OTP, Đặt lại mật khẩu, Đổi mật khẩu trong Profile và xử lý triệt để kết quả trả về từ Google Login (đặc biệt trên Mobile/App).

---

## 2. Kế hoạch triển khai giao diện và chức năng Auth trên Flutter

Để hoàn thiện Module Auth trên Flutter đồng bộ với sức mạnh của Backend, chúng ta cần thực hiện các bước sau:

### Bước 1: Mở rộng `AuthProvider` và API Client
Cập nhật file `lib/features/auth/providers/auth_provider.dart` để gọi các API còn thiếu:
- `forgotPassword(String email)`
- `verifyOtp(String email, String otp)`
- `resetPassword(String token, String newPassword)`
- `changePassword(String oldPassword, String newPassword)`
- `fetchCurrentUser()` (gọi `/api/auth/me` để lấy profile)
- `logout()`

### Bước 2: Xây dựng luồng "Quên mật khẩu" (Forgot Password Flow)
Thiết kế 3 màn hình UI đồng bộ với phong cách thiết kế hiện tại của ứng dụng (màu `primaryColor`, giao diện sạch, sang trọng):
1. **`forgot_password_screen.dart`**: 
   - Form nhập Email.
   - Nút "Gửi mã OTP".
   - Sau khi gửi thành công -> Điều hướng sang màn hình nhập OTP.
2. **`verify_otp_screen.dart`**:
   - Giao diện nhập mã OTP (sử dụng package `pinput` để UI đẹp hơn).
   - Nút "Xác nhận".
   - Gọi API verify, thành công nhận token -> Điều hướng sang đặt lại mật khẩu.
3. **`reset_password_screen.dart`**:
   - Form nhập "Mật khẩu mới" và "Xác nhận mật khẩu".
   - Nút "Cập nhật mật khẩu".
   - Cập nhật thành công -> Quay lại màn hình đăng nhập.

### Bước 3: Cải thiện Social Login (Google OAuth2)
Nút "Tiếp tục với Google" trong `login_screen.dart` hiện tại dùng `url_launcher` mở browser. 
- **Với Web**: Xử lý listener lấy URL redirect về có chứa `token`.
- **Với Mobile (Android/iOS)**: Cần thiết lập Deep Linking (`uni_links` hoặc `app_links`) để backend redirect token ngược lại App. Hoặc sử dụng `flutter_web_auth_2` để mở in-app browser và hứng token trực tiếp.

### Bước 4: Xây dựng màn hình Profile & Change Password
1. **`profile_screen.dart`**: 
   - Hiển thị thông tin người dùng (`fullName`, `avatarUrl`, `email`).
   - Nút Đăng xuất (`logout`).
2. **`change_password_screen.dart` (hoặc BottomSheet)**: 
   - Cho phép người dùng đang đăng nhập đổi mật khẩu.
   - Yêu cầu nhập "Mật khẩu cũ", "Mật khẩu mới" và "Xác nhận mật khẩu mới".

### Bước 5: Hoàn thiện Route và Navigation
- Đảm bảo cơ chế Private Route: Tự động điều hướng về `LoginScreen` nếu mất token hoặc phiên làm việc hết hạn (`401 Unauthorized`).
- Splash Screen để kiểm tra token local khởi tạo trạng thái đăng nhập.

---

## 3. Đề xuất Actions tiếp theo
Nếu bạn đồng ý với kế hoạch này, tôi có thể bắt đầu bằng việc:
1. Viết code cho các màn hình **Forgot Password / OTP / Reset Password** để hoàn thành luồng lấy lại mật khẩu.
2. Hoặc nâng cấp **AuthProvider** và xử lý **Google Login** cho cả Mobile và Web.

Vui lòng kiểm tra kế hoạch. Bạn muốn tôi bắt đầu implement phần nào trước?
