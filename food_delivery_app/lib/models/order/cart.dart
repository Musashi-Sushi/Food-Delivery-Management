import 'cart_item.dart';
import '../restaurant/menu_item.dart';

class Cart {
  String id;
  String customerId;
  String? restaurantId;
  List<CartItem> items = [];

  Cart({required this.id, required this.customerId, this.restaurantId});

  int get totalItems {
    int total = 0;
    for (var item in items) {
      total += item.quantity;
    }
    return total;
  }

  void addItem(MenuItem menuItem, int quantity) {
    final existing = items.where((i) => i.menuItem.id == menuItem.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
      return;
    }

    final newId = items.isEmpty
        ? "1"
        : (items
                      .map((e) => int.tryParse(e.id) ?? 0)
                      .reduce((a, b) => a > b ? a : b) +
                  1)
              .toString();

    items.add(
      CartItem(id: newId, cartId: id, menuItem: menuItem, quantity: quantity),
    );
  }

  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }

  void setRestaurant(String restaurantId) {
    this.restaurantId = restaurantId;
  }

  void incrementQuantity(String itemId) {
    for (final item in items) {
      if (item.id == itemId) {
        item.quantity++;
        break;
      }
    }
  }

  void decrementQuantity(String itemId) {
    for (final item in items) {
      if (item.id == itemId) {
        if (item.quantity > 1) item.quantity--;
        break;
      }
    }
  }

  void updateQuantity(String itemId, int quantity) {
    for (final item in items) {
      if (item.id == itemId) {
        item.quantity = quantity < 1 ? 1 : quantity;
        break;
      }
    }
  }

  void clearCart() {
    items.clear();
    restaurantId = null;
  }

  double calculateTotal() {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Cart clone() {
    final cloned = Cart(
      id: id,
      customerId: customerId,
      restaurantId: restaurantId,
    );
    cloned.items = items
        .map(
          (e) => CartItem(
            id: e.id,
            cartId: e.cartId,
            menuItem: e.menuItem,
            quantity: e.quantity,
          ),
        )
        .toList();
    return cloned;
  }
}
