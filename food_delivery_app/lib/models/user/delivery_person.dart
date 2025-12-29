import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../delivery/delivery.dart';
import '../enums/delivery_status.dart';
import 'user.dart';
import '../enums/user_type.dart';
import '../../services/firestore/delivery_service.dart';
import '../../services/firestore/order_service.dart';

/// Rider who delivers orders.
class DeliveryPerson extends User {
  DeliveryStatus status;

  DeliveryPerson({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.createdAt,
    required this.status,
    super.address,
  });

  static Future<UserCredential> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return User.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      userType: UserType.rider,
    );
  }

  Stream<List<Delivery>> viewAssignedDeliveries() {
    final service = DeliveryService();
    return service.streamRiderDeliveries(id).map((docs) {
      return docs.map((d) {
        final data = d.data();
        final now = DateTime.now();
        return Delivery(
          id: d.id,
          orderId: (data['order_id'] as String?) ?? '',
          riderId: (data['rider_id'] as String?) ?? id,
          status: DeliveryStatus.values.firstWhere(
            (e) => e.name == (data['status'] as String? ?? 'assigned'),
            orElse: () => DeliveryStatus.assigned,
          ),
          currentLat: (data['current_lat'] as num?)?.toDouble() ?? 0,
          currentLng: (data['current_lng'] as num?)?.toDouble() ?? 0,
          assignedAt: now,
        );
      }).toList();
    });
  }

  Future<void> acceptDeliveryAssignment({
    required String orderId,
    required String restaurantId,
    required String customerId,
    required double currentLat,
    required double currentLng,
  }) async {
    await Delivery.create(
      orderId: orderId,
      restaurantId: restaurantId,
      customerId: customerId,
      riderId: id,
      currentLat: currentLat,
      currentLng: currentLng,
      status: DeliveryStatus.assigned,
    );
    await OrderService().updateOrderFields(orderId, {'rider_id': id});
  }

  Future<void> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus newStatus,
  ) async {
    final d = Delivery(
      id: deliveryId,
      orderId: '',
      riderId: id,
      status: newStatus,
      currentLat: 0,
      currentLng: 0,
      assignedAt: DateTime.now(),
    );
    await d.updateStatus(newStatus);
    if (newStatus == DeliveryStatus.onTheWay) {
      final doc = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .get();
      final orderId = (doc.data() ?? const {})['order_id'] as String?;
      if (orderId != null) {
        await OrderService().updateOrderFields(orderId, {
          'delivery_status': newStatus.name,
        });
      }
    }
    if (newStatus == DeliveryStatus.delivered) {
      final doc = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .get();
      final orderId = (doc.data() ?? const {})['order_id'] as String?;
      if (orderId != null) {
        await OrderService().updateOrderFields(orderId, {
          'delivery_status': newStatus.name,
          'status': 'delivered',
        });
      }
    }
  }

  Future<void> updateLiveLocation(
    String deliveryId,
    double lat,
    double lng,
  ) async {
    final d = Delivery(
      id: deliveryId,
      orderId: '',
      riderId: id,
      status: DeliveryStatus.assigned,
      currentLat: 0,
      currentLng: 0,
      assignedAt: DateTime.now(),
    );
    await d.updateLocation(lat, lng);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    await User.staticLogin(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    await User.staticLogout();
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    await User.staticUpdateProfile(name: name, phone: phone, address: address);
  }
}
