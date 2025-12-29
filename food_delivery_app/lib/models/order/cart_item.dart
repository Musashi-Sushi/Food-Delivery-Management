import '../restaurant/menu_item.dart';

class CartItem {
  String id;
  String cartId;
  MenuItem menuItem;
  int quantity;

  CartItem({
    required this.id,
    required this.cartId,
    required this.menuItem,
    required this.quantity,
  });

  double get totalPrice => menuItem.price * quantity;
}
