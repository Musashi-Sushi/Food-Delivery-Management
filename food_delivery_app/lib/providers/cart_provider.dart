import 'package:flutter_riverpod/legacy.dart';

import '../models/order/cart.dart';
import '../models/restaurant/menu_item.dart';

/// Riverpod state notifier that manages the in-memory shopping cart.
class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart(id: "1", customerId: "1"));

  void addItem(MenuItem menuItem, int quantity) {
    final cart = state;
    cart.addItem(menuItem, quantity);
    state = cart.clone();
  }

  void setRestaurantId(String restaurantId) {
    final cart = state;
    cart.setRestaurant(restaurantId);
    state = cart.clone();
  }

  void incrementQuantity(String cartItemId) {
    final cart = state;
    cart.incrementQuantity(cartItemId);
    state = cart.clone();
  }

  void decrementQuantity(String cartItemId) {
    final cart = state;
    cart.decrementQuantity(cartItemId);
    state = cart.clone();
  }

  void removeItem(String cartItemId) {
    final cart = state;
    cart.removeItem(cartItemId);
    state = cart.clone();
  }

  void clearCart() {
    final cart = state;
    cart.clearCart();
    state = cart.clone();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});
