class Car {
  final int carId;
  final String carName;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  final String color;
  final int seats;
  final String fuelType;
  final String transmission;
  final String carStatus;
  final double pricePerDay;
  final String? description;
  final String? thumbnailUrl;

  Car({
    required this.carId,
    required this.carName,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    required this.seats,
    required this.fuelType,
    required this.transmission,
    required this.carStatus,
    required this.pricePerDay,
    this.description,
    this.thumbnailUrl,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carId: json['carId'] ?? 0,
      carName: json['carName'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      licensePlate: json['licensePlate'] ?? '',
      color: json['color'] ?? '',
      seats: json['seats'] ?? 4,
      fuelType: json['fuelType'] ?? 'GASOLINE',
      transmission: json['transmission'] ?? 'AUTOMATIC',
      carStatus: json['carStatus'] ?? 'AVAILABLE',
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}
