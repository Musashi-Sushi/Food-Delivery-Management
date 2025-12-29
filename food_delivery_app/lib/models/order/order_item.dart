class OrderItem {
  String id;
  String orderId;
  String menuItemId;
  String menuItemName;
  int quantity;
  double price;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.price,
  });
}
