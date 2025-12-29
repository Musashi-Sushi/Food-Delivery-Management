class MenuItem {
  String id;
  String name;
  String description;
  double price;
  String categoryId;
  bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.available,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    return MenuItem(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId:
          map['categoryId'] as String? ?? map['category_id'] as String? ?? '',
      available:
          (map['available'] as bool?) ??
          (map['availability'] as bool?) ??
          false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'available': available,
    };
  }
}
