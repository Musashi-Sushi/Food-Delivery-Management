enum AdminRole { superAdmin, finance, operations }

enum DeliveryStatus { assigned, pickedUp, onTheWay, delivered }

abstract class User {
  int id;
  String fullName;
  String emailAddress;
  String phoneNumber;
  String password;
  DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.emailAddress,
    required this.phoneNumber,
    required this.password,
    required this.createdAt,
  });
}

class DeliveryPerson extends User {
  DeliveryStatus status;
  double? currentLat;
  double? currentLng;

  DeliveryPerson({
    required super.id,
    required super.fullName,
    required super.emailAddress,
    required super.phoneNumber,
    required super.password,
    required super.createdAt,
    required this.status,
    this.currentLat,
    this.currentLng,
  });
}

class Delivery {
  int id;
  int orderId;
  int riderId;
  DeliveryStatus status;
  double currentLat;
  double currentLng;

  Delivery({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.status,
    required this.currentLat,
    required this.currentLng,
  });
}
