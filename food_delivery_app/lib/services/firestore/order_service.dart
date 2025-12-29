import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../models/order/order.dart';

/// Firestore persistence layer for orders.
class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  /// Check if the given customer currently has an "active" order.
  ///
  /// An active order is one whose status is NOT in a terminal state like
  /// completed / cancelled / delivered / rejected.
  ///
  /// This method is defensive: if anything goes wrong with the Firestore query
  /// (e.g. missing index), it will *not* block the user from placing an order
  /// and will return `false` (no active orders).
  Future<bool> hasActiveOrderForCustomer(String customerId) async {
    try {
      final snapshot = await _ordersCol
          .where('customer_id', isEqualTo: customerId)
          // No orderBy here to avoid requiring a composite index just for this
          // simple existence check.
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final data = snapshot.docs.first.data();
      final status = data['status'] as String? ?? 'pending';
      final deliveryStatus = data['delivery_status'] as String? ?? '';

      final isTerminalStatus =
          status == 'completed' ||
          status == 'cancelled' ||
          status == 'delivered' ||
          status == 'rejected';
      final isDelivered = deliveryStatus == 'delivered';

      return !(isTerminalStatus || isDelivered);
    } catch (_) {
      // Fail-open: if we cannot determine that there *is* an active order,
      // don't block the user from placing one.
      return false;
    }
  }

  /// Save the given [order] into Firestore and return a copy with a
  /// server-generated ID.
  Future<Order> saveOrder(Order order) async {
    final docRef = _ordersCol.doc();

    final data = <String, dynamic>{
      'customer_id': order.customerId,
      'customer_name': order.customerName,
      'restaurant_id': order.restaurantId,
      'status': order.status.name,
      'delivery_status': order.deliveryStatus.name,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'total_amount': order.totalAmount,
      'delivery_address': order.deliveryAddress,
      'payment_method': order.paymentMethod.name,
      'payment_status': order.paymentStatus.name,
      'items': order.items
          .map(
            (item) => {
              'menu_item_id': item.menuItemId,
              'menu_item_name': item.menuItemName,
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList(),
    };

    await docRef.set(data);

    // Return a new Order instance with the Firestore ID.
    final savedOrder = Order(
      customerName: order.customerName,
      id: docRef.id,
      customerId: order.customerId,
      restaurantId: order.restaurantId,
      status: order.status,
      deliveryStatus: order.deliveryStatus,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      totalAmount: order.totalAmount,
      deliveryAddress: order.deliveryAddress,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
    )..items = order.items;

    return savedOrder;
  }

  Future<void> updateOrderFields(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    final docRef = _ordersCol.doc(orderId);
    final payload = {...data, 'updated_at': FieldValue.serverTimestamp()};
    await docRef.update(payload);
  }
}
