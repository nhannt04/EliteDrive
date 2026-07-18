class Rental {
  final int rentalId;
  final String customerName;
  final String customerEmail;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final String status;
  final String createdDate;
  final int? carId;
  final String? carName;
  final String? brand;
  final String? thumbnailUrl;
  final int? seats;
  final String? transmission;

  Rental({
    required this.rentalId,
    required this.customerName,
    required this.customerEmail,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdDate,
    this.carId,
    this.carName,
    this.brand,
    this.thumbnailUrl,
    this.seats,
    this.transmission,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: json['rentalId'] ?? 0,
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdDate: json['createdDate'] ?? '',
      carId: json['carId'],
      carName: json['carName'],
      brand: json['brand'],
      thumbnailUrl: json['thumbnailUrl'],
      seats: json['seats'],
      transmission: json['transmission'],
    );
  }
}
