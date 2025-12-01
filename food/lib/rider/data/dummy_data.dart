import 'package:food/rider/models/models.dart';

final DeliveryPerson currentRider = DeliveryPerson(
  id: 1,
  fullName: "Ahsan Malik",
  emailAddress: "ahsan@dailydeli.com",
  phoneNumber: "+44 7700 900123",
  password: "secret",
  createdAt: DateTime.now(),
  status: DeliveryStatus.onTheWay,
  currentLat: 40.7128,
  currentLng: -74.0060,
);

final List<Delivery> assignedDeliveries = [
  Delivery(
    id: 1,
    orderId: 101,
    riderId: 1,
    status: DeliveryStatus.onTheWay,
    currentLat: 40.7128,
    currentLng: -74.0060,
  ),
  Delivery(
    id: 2,
    orderId: 102,
    riderId: 1,
    status: DeliveryStatus.pickedUp,
    currentLat: 40.7131,
    currentLng: -74.0055,
  ),
  Delivery(
    id: 3,
    orderId: 103,
    riderId: 1,
    status: DeliveryStatus.assigned,
    currentLat: 40.7140,
    currentLng: -74.0070,
  ),
];

final List<Delivery> completedDeliveries = [
  Delivery(
    id: 4,
    orderId: 90,
    riderId: 1,
    status: DeliveryStatus.delivered,
    currentLat: 40.7150,
    currentLng: -74.0040,
  ),
  Delivery(
    id: 5,
    orderId: 91,
    riderId: 1,
    status: DeliveryStatus.delivered,
    currentLat: 40.7160,
    currentLng: -74.0030,
  ),
];
