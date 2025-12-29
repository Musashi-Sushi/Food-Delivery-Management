import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/models/restaurant/category_registry.dart';

import '../restaurant/menu_item.dart';
import 'category.dart';

class Restaurant {
  String id;
  String name;
  String cuisine;
  double rating;
  String ownerId;
  int deliveryTimeMinutes;
  String imageUrl;
  double latitude;
  double longitude;
  List<Category> categories;
  bool isApproved;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.ownerId,
    required this.deliveryTimeMinutes,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.isApproved,
  });

  factory Restaurant.fromFirestore(Map<String, dynamic> doc) {
    final categoryIds = List<String>.from(doc['categories'] ?? []);

    final categories = categoryIds
        .map((id) => CategoryRegistry.getById(id))
        .where((c) => c != null)
        .map((c) => c!)
        .toList();

    return Restaurant(
      id: doc['restaurant_id'],
      name: doc['name'],
      cuisine: doc['cuisine'],
      rating: (doc['rating'] as num).toDouble(),
      ownerId: doc['owner_id'],
      deliveryTimeMinutes: doc['delivery_time'],
      imageUrl: doc['image'],
      latitude: (doc['latitude'] as num).toDouble(),
      longitude: (doc['longitude'] as num).toDouble(),
      categories: categories,
      isApproved: (doc['isApproved'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'restaurant_id': id,
      'name': name,
      'cuisine': cuisine,
      'rating': rating,
      'owner_id': ownerId,
      'delivery_time': deliveryTimeMinutes,
      'image': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categories.map((c) => c.id).toList(),
      'isApproved': isApproved,
    };
  }

  Future<List<MenuItem>> getMenu() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(id)
        .collection('menu_items')
        .where('available', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
        .toList();
  }
}
