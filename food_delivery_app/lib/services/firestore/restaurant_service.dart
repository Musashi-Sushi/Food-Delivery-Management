import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/models/restaurant/restaurant.dart';

class RestaurantRepository {
  final FirebaseFirestore _db;

  RestaurantRepository(this._db);

  Future<List<Restaurant>> fetchAllRestaurants() async {
    final snapshot = await _db.collection('restaurants').get();

    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc.data()))
        .toList();
  }
}

class RestaurantService {
  final RestaurantRepository _repository;

  RestaurantService(this._repository);

  Future<List<Restaurant>> getRestaurants() async {
    // Additional filtering, caching, sorting can be done here
    return await _repository.fetchAllRestaurants();
  }
}
