import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_app/services/firestore/restaurant_service.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final restaurantRepositoryProvider = Provider((ref) {
  return RestaurantRepository(ref.watch(firestoreProvider));
});

final restaurantServiceProvider = Provider((ref) {
  return RestaurantService(ref.watch(restaurantRepositoryProvider));
});

final allRestaurantsProvider = FutureProvider((ref) async {
  return await ref.watch(restaurantServiceProvider).getRestaurants();
});
