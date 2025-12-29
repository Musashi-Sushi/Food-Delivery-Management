import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/delivery_status.dart';
import '../../services/firestore/delivery_service.dart';

class Delivery {
  String id;
  String orderId;
  String riderId;
  DeliveryStatus status;
  double currentLat;
  double currentLng;
  DateTime assignedAt;
  DateTime? deliveredAt;

  Delivery({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.status,
    required this.currentLat,
    required this.currentLng,
    required this.assignedAt,
    this.deliveredAt,
  });

  static Future<Delivery> create({
    required String orderId,
    required String restaurantId,
    required String customerId,
    String? riderId,
    required double currentLat,
    required double currentLng,
    DeliveryStatus status = DeliveryStatus.assigned,
  }) async {
    final id = await DeliveryService().createDelivery(
      orderId: orderId,
      restaurantId: restaurantId,
      customerId: customerId,
      riderId: riderId,
      currentLat: currentLat,
      currentLng: currentLng,
      status: status,
    );
    return Delivery(
      id: id,
      orderId: orderId,
      riderId: riderId ?? '',
      status: status,
      currentLat: currentLat,
      currentLng: currentLng,
      assignedAt: DateTime.now(),
    );
  }

  static Future<bool> tryAssignRider({
    required String deliveryId,
    required String riderId,
  }) async {
    return DeliveryService().tryAssignRider(
      deliveryId: deliveryId,
      riderId: riderId,
    );
  }

  Future<void> assignRider(String newRiderId) async {
    riderId = newRiderId;
    await _update({'rider_id': newRiderId});
  }

  Future<void> updateStatus(DeliveryStatus newStatus) async {
    status = newStatus;
    final Map<String, dynamic> data = {'status': newStatus.name};
    if (newStatus == DeliveryStatus.delivered) {
      deliveredAt = DateTime.now();
      data['delivered_at'] = FieldValue.serverTimestamp();
    }
    await _update(data);
  }

  Future<void> updateLocation(double lat, double lng) async {
    currentLat = lat;
    currentLng = lng;
    await _update({'current_lat': lat, 'current_lng': lng});
  }

  Future<void> updateFields(Map<String, dynamic> data) async {
    await _update(data);
  }

  Future<void> _update(Map<String, dynamic> data) async {
    final service = DeliveryService();
    await service.updateDeliveryFields(id, data);
  }
}
