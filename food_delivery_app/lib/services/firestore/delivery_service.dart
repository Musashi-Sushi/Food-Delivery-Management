import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/enums/delivery_status.dart';

class DeliveryService {
  DeliveryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _deliveriesCol =>
      _firestore.collection('deliveries');

  Future<String> createDelivery({
    required String orderId,
    required String restaurantId,
    required String customerId,
    String? riderId,
    required double currentLat,
    required double currentLng,
    DeliveryStatus status = DeliveryStatus.assigned,
  }) async {
    final docRef = _deliveriesCol.doc();
    final data = <String, dynamic>{
      'delivery_id': docRef.id,
      'order_id': orderId,
      'restaurant_id': restaurantId,
      'customer_id': customerId,
      'rider_id': riderId,
      'status': status.name,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'assigned_at': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return docRef.id;
  }

  Future<bool> tryAssignRider({
    required String deliveryId,
    required String riderId,
  }) async {
    return _firestore.runTransaction((tx) async {
      final docRef = _deliveriesCol.doc(deliveryId);
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;
      final data = snap.data()!;
      final existing = data['rider_id'];
      if (existing != null && (existing as String).isNotEmpty) {
        return false;
      }
      tx.update(docRef, {
        'rider_id': riderId,
        'status': DeliveryStatus.assigned.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> updateDeliveryFields(
    String deliveryId,
    Map<String, dynamic> data,
  ) async {
    final docRef = _deliveriesCol.doc(deliveryId);
    final payload = {...data, 'updated_at': FieldValue.serverTimestamp()};
    await docRef.update(payload);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamRiderDeliveries(String riderId, {bool completed = false}) {
    final base = _deliveriesCol.where('rider_id', isEqualTo: riderId);
    final query = completed
        ? base.where('status', isEqualTo: DeliveryStatus.delivered.name)
        : base.where('status', isNotEqualTo: DeliveryStatus.delivered.name);
    return query.snapshots().map((s) => s.docs);
  }

  Stream<QueryDocumentSnapshot<Map<String, dynamic>>?> streamByOrderId(
    String orderId,
  ) {
    return _deliveriesCol
        .where('order_id', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : s.docs.first);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamAvailableRequests() {
    return _deliveriesCol
        .where('status', isEqualTo: DeliveryStatus.requested.name)
        .snapshots()
        .map((s) => s.docs);
  }
}
