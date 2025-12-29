import '../enums/delivery_status.dart';
import '../enums/order_status.dart';
import '../enums/payment_method.dart';
import '../enums/payment_status.dart';
import 'order_item.dart';
import '../../services/firestore/order_service.dart';

/// Represents a placed order.
class Order {
  String id;
  String customerId;
  String customerName;
  String restaurantId;
  OrderStatus status;
  DeliveryStatus deliveryStatus;
  DateTime createdAt;
  DateTime updatedAt;
  List<OrderItem> items = [];
  double totalAmount;
  String deliveryAddress;
  PaymentMethod paymentMethod;
  PaymentStatus paymentStatus;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.status,
    required this.deliveryStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  double calculateTotal() {
    double total = 0;

    for (var item in items) {
      total += item.price * item.quantity;
    }

    totalAmount = total;
    return totalAmount;
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'restaurant_id': restaurantId,
      'status': status.name,
      'delivery_status': deliveryStatus.name,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod.name,
      'payment_status': paymentStatus.name,
      'items': items
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
  }

  Future<Order> save() async {
    final service = OrderService();
    final saved = await service.saveOrder(this);
    id = saved.id;
    return saved;
  }

  static Future<bool> hasActiveOrderForCustomer(String customerId) async {
    final service = OrderService();
    return service.hasActiveOrderForCustomer(customerId);
  }

  Future<void> updateStatus(OrderStatus newStatus) async {
    status = newStatus;
    final service = OrderService();
    await service.updateOrderFields(id, {'status': newStatus.name});
  }

  Future<void> updateDeliveryStatus(DeliveryStatus newStatus) async {
    deliveryStatus = newStatus;
    final service = OrderService();
    await service.updateOrderFields(id, {'delivery_status': newStatus.name});
  }

  Future<void> markPaid() async {
    paymentStatus = PaymentStatus.paid;
    final service = OrderService();
    await service.updateOrderFields(id, {'payment_status': paymentStatus.name});
  }
}
