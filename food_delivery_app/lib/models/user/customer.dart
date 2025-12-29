import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../services/firestore/restaurant_service.dart';
import '../enums/delivery_status.dart';
import '../enums/order_status.dart';
import '../enums/payment_method.dart';
import '../enums/payment_status.dart';
import '../order/cart.dart';
import '../order/order.dart';
import '../order/order_item.dart';
import '../restaurant/menu_item.dart';
import '../restaurant/restaurant.dart';
import 'user.dart';
import '../enums/user_type.dart';

class Customer extends User {
  Cart cart;
  List<Order> orderHistory = [];
  Customer({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.createdAt,
    required this.cart,
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
      userType: UserType.customer,
    );
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

  Future<List<Restaurant>> searchRestaurantByName(String name) async {
    final service = RestaurantService(
      RestaurantRepository(FirebaseFirestore.instance),
    );
    final list = await service.getRestaurants();
    final q = name.toLowerCase();
    return list.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  Future<List<Restaurant>> searchRestaurantByLocation(String location) async {
    final service = RestaurantService(
      RestaurantRepository(FirebaseFirestore.instance),
    );
    final list = await service.getRestaurants();
    final q = location.toLowerCase();
    return list.where((r) => r.cuisine.toLowerCase().contains(q)).toList();
  }

  Future<List<Restaurant>> searchRestaurantByCategory(String category) async {
    final service = RestaurantService(
      RestaurantRepository(FirebaseFirestore.instance),
    );
    final list = await service.getRestaurants();
    final q = category.toLowerCase();
    return list
        .where((r) => r.categories.any((c) => c.name.toLowerCase().contains(q)))
        .toList();
  }

  Future<List<MenuItem>> viewRestaurantMenu(int restaurantId) async {
    final idStr = restaurantId.toString();
    final restaurant = Restaurant(
      id: idStr,
      name: '',
      cuisine: '',
      rating: 0,
      ownerId: '',
      deliveryTimeMinutes: 0,
      imageUrl: '',
      latitude: 0,
      longitude: 0,
      categories: const [],
      isApproved: true,
    );
    return restaurant.getMenu();
  }

  void addToCart(int menuItemId, int quantity) {
    final rid = cart.restaurantId;
    if (rid == null || rid.isEmpty) {
      throw StateError('Restaurant not set for cart');
    }
    final idStr = menuItemId.toString();
    final menuItem = MenuItem(
      id: idStr,
      name: '',
      description: '',
      price: 0,
      categoryId: '',
      available: true,
    );
    cart.addItem(menuItem, quantity);
  }

  void removeFromCart(int menuItemId) {
    final idStr = menuItemId.toString();
    final target = cart.items.firstWhere(
      (ci) => ci.menuItem.id == idStr,
      orElse: () => throw StateError('Item not in cart'),
    );
    cart.removeItem(target.id);
  }

  void clearCart() {
    cart.clearCart();
  }

  Future<Order> placeOrder({
    required String deliveryAddress,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    String? restaurantId,
  }) async {
    if (cart.items.isEmpty) {
      throw StateError('Cannot place an order with an empty cart');
    }

    // For now we assume all items belong to a single restaurant.
    final resolvedRestaurantId = restaurantId ?? cart.restaurantId ?? 'unknown';

    final now = DateTime.now();

    final order = Order(
      id: 'temp',
      customerId: id,
      customerName: name,
      restaurantId: resolvedRestaurantId,
      status: OrderStatus.pending,
      deliveryStatus: DeliveryStatus.assigned,
      createdAt: now,
      updatedAt: now,
      totalAmount: cart.calculateTotal(),
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );

    // Map cart items to order items.
    order.items = cart.items.asMap().entries.map((entry) {
      final index = entry.key;
      final cartItem = entry.value;
      return OrderItem(
        id: '${index + 1}',
        orderId: order.id,
        menuItemId: cartItem.menuItem.id,
        menuItemName: cartItem.menuItem.name,
        quantity: cartItem.quantity,
        price: cartItem.menuItem.price,
      );
    }).toList();

    order.calculateTotal();

    // Store in local history and clear the in-memory cart.
    orderHistory.add(order);
    cart.clearCart();

    return order;
  }

  Future<void> submitReview(
    int restaurantId,
    int orderId,
    int rating,
    String comment,
  ) async {
    await FirebaseFirestore.instance.collection('reviews').add({
      'restaurant_id': restaurantId.toString(),
      'order_id': orderId.toString(),
      'customer_id': id,
      'rating': rating,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> makePayment(
    int orderId,
    double amount,
    PaymentMethod method,
  ) async {
    await FirebaseFirestore.instance.collection('payments').add({
      'order_id': orderId.toString(),
      'customer_id': id,
      'amount': amount,
      'method': method.name,
      'status': 'paid',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  void applyPromoCode(String code) {}

  Future<void> requestRefund(int paymentId, String reason) async {
    await FirebaseFirestore.instance.collection('refunds').add({
      'payment_id': paymentId.toString(),
      'customer_id': id,
      'reason': reason,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
