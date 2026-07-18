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

  static String _parseDate(dynamic date) {
    if (date == null) return '';
    if (date is String) return date;
    if (date is List) {
      if (date.length >= 3) {
        final year = date[0];
        final month = date[1].toString().padLeft(2, '0');
        final day = date[2].toString().padLeft(2, '0');
        return '$year-$month-$day';
      }
    }
    return date.toString();
  }

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: int.tryParse(json['rentalId']?.toString() ?? '') ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      totalPrice: double.tryParse(json['totalPrice']?.toString() ?? '') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      createdDate: _parseDate(json['createdDate']),
      carId: int.tryParse(json['carId']?.toString() ?? ''),
      carName: json['carName']?.toString(),
      brand: json['brand']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      seats: int.tryParse(json['seats']?.toString() ?? ''),
      transmission: json['transmission']?.toString(),
    );
  }
}
