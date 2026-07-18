class UserProfileModel {
  final int userId;
  final String username;
  final String fullName;
  final String? address;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? dateOfBirth; // Format YYYY-MM-DD
  final String? identifyId;
  final String? driverLicenceId;
  final List<String> roles;
  final bool isEnabled;
  final String? userType;

  UserProfileModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.address,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.dateOfBirth,
    this.identifyId,
    this.driverLicenceId,
    this.roles = const [],
    this.isEnabled = true,
    this.userType,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      address: json['address'],
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'],
      identifyId: json['identifyId'],
      driverLicenceId: json['driverLicenceId'],
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isEnabled: json['isEnabled'] ?? true,
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'fullName': fullName,
      'address': address,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth,
      'identifyId': identifyId,
      'driverLicenceId': driverLicenceId,
    };
  }
}
