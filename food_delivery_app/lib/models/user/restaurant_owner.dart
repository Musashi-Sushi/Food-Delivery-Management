import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import '../enums/order_status.dart';
import '../order/order.dart';
import '../restaurant/menu_item.dart';
import '../restaurant/restaurant.dart';
import 'user.dart';
import '../enums/user_type.dart';
import '../../services/firestore/order_service.dart';
import '../enums/delivery_status.dart';
import '../enums/payment_method.dart';
import '../enums/payment_status.dart';

/// Owner / manager of a restaurant.
class RestaurantOwner extends User {
  int restaurantId;

  RestaurantOwner({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.createdAt,
    required this.restaurantId,
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
      userType: UserType.restaurantOwner,
    );
  }

  Future<String?> _resolveRestaurantDocId() async {
    if (restaurantId != 0) return restaurantId.toString();
    final snap = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('owner_id', isEqualTo: id)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    final fieldId = data['restaurant_id'] as String?;
    return fieldId ?? snap.docs.first.id;
  }

  Future<void> addMenuItem(MenuItem item) async {
    final rid = await _resolveRestaurantDocId();
    if (rid == null) return;
    final col = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(rid)
        .collection('menu_items');
    final docRef = col.doc();
    final data = {
      ...item.toMap(),
      'id': docRef.id,
      'available': true,
      'availability': true,
    };
    await docRef.set(data);
    item.id = docRef.id;
  }

  Future<void> updateMenuItem(
    String itemId, {
    String? name,
    double? price,
    String? categoryId,
    bool? available,
  }) async {
    final rid = await _resolveRestaurantDocId();
    if (rid == null) return;
    final doc = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(rid)
        .collection('menu_items')
        .doc(itemId);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (available != null) {
      data['available'] = available;
      data['availability'] = available;
    }
    if (data.isEmpty) return;
    await doc.update(data);
  }

  Future<void> deleteMenuItem(String itemId) async {
    final rid = await _resolveRestaurantDocId();
    if (rid == null) return;
    final doc = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(rid)
        .collection('menu_items')
        .doc(itemId);
    await doc.delete();
  }

  Future<List<Restaurant>> getMyRestaurants() async {
    final snap = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('owner_id', isEqualTo: id)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['restaurant_id'] ??= d.id;
      return Restaurant.fromFirestore(data);
    }).toList();
  }

  Future<Restaurant> createRestaurant({
    required String name,
    required String cuisine,
    required int deliveryTimeMinutes,
    required String imageUrl,
    required double latitude,
    required double longitude,
    List<String> categoryIds = const [],
  }) async {
    final col = FirebaseFirestore.instance.collection('restaurants');
    final docRef = col.doc();
    final data = {
      'restaurant_id': docRef.id,
      'name': name,
      'cuisine': cuisine,
      'rating': 0.0,
      'owner_id': id,
      'delivery_time': deliveryTimeMinutes,
      'image': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categoryIds,
      'isApproved': false,
      'created_at': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return Restaurant.fromFirestore(data);
  }

  Future<void> categorizeItem(String itemId, String categoryId) async {
    await updateMenuItem(itemId, categoryId: categoryId);
  }

  Future<void> markItemOutOfStock(String itemId) async {
    await updateMenuItem(itemId, available: false);
  }

  Future<void> acceptOrder(String orderId) async {
    await OrderService().updateOrderFields(orderId, {'status': 'accepted'});
  }

  Future<void> rejectOrder(String orderId) async {
    await OrderService().updateOrderFields(orderId, {'status': 'rejected'});
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await OrderService().updateOrderFields(orderId, {'status': status.name});
  }

  Future<Order?> viewOrderDetails(String orderId) async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final now = DateTime.now();
    final o = Order(
      id: doc.id,
      customerId: (data['customer_id'] as String?) ?? '',
      customerName: (data['customer_name'] as String?) ?? '',
      restaurantId: (data['restaurant_id'] as String?) ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      deliveryStatus: DeliveryStatus.values.firstWhere(
        (e) => e.name == (data['delivery_status'] as String? ?? 'assigned'),
        orElse: () => DeliveryStatus.assigned,
      ),
      createdAt: now,
      updatedAt: now,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: (data['delivery_address'] as String?) ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (data['payment_method'] as String? ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (data['payment_status'] as String? ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
    );
    return o;
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
