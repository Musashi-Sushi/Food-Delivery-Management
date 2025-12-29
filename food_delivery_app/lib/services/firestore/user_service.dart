import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/enums/user_status.dart';
import '../../models/enums/user_type.dart';
import '../../models/user/user.dart' as domain_user;
import '../../models/user/customer.dart';
import '../../models/user/restaurant_owner.dart';
import '../../models/user/delivery_person.dart';
import '../../models/order/cart.dart';
import '../../models/enums/delivery_status.dart';

/// Handles reading and writing user profiles from the `users` collection.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// Create a user document for the given [uid].
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required UserType userType,
    UserStatus status = UserStatus.active,
  }) async {
    await _usersCol.doc(uid).set({
      'user_id': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'user_type': userType.firestoreValue,
      'status': status.firestoreValue,
      'created_at': FieldValue.serverTimestamp(),
      'profile_image': '',
      'fcm_token': '',
      // New users start without an address; can be filled from profile screen.
      'address': '',
    });
  }

  /// Update only the address field for the given user.
  Future<void> updateAddress(String uid, String address) async {
    await _usersCol.doc(uid).update({'address': address});
  }

  Future<void> updateProfileFields(
    String uid, {
    String? name,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (data.isEmpty) return;
    await _usersCol.doc(uid).update(data);
  }

  /// Get the raw user profile data (or null if it doesn't exist).
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _usersCol.doc(uid).get();
    return snap.data();
  }

  /// Build a domain [User] object (Customer, RestaurantOwner, etc.) from the
  /// Firestore document.
  Future<domain_user.User?> getDomainUser(String uid) async {
    final data = await getUserProfile(uid);
    if (data == null) return null;

    final name = data['name'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final phone = data['phone'] as String? ?? '';
    final address = data['address'] as String? ?? '';
    final userTypeStr = data['user_type'] as String?;
    final userType = UserTypeFirestore.fromFirestore(userTypeStr);

    final createdAtField = data['created_at'];
    DateTime createdAt;
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else {
      createdAt = DateTime.now();
    }

    // Password is managed by Firebase Auth, so we don't store it here.
    const password = '';

    switch (userType) {
      case UserType.customer:
        // Simple empty cart with dummy numeric IDs to keep things easy.
        return Customer(
          id: uid,
          name: name,
          email: email,
          phone: phone,
          password: password,
          createdAt: createdAt,
          cart: Cart(id: '0', customerId: '0'),
          address: address,
        );
      case UserType.restaurantOwner:
        // Restaurant id not stored yet, use 0 as placeholder.
        return RestaurantOwner(
          id: uid,
          name: name,
          email: email,
          phone: phone,
          password: password,
          createdAt: createdAt,
          restaurantId: 0,
        );
      case UserType.rider:
        return DeliveryPerson(
          id: uid,
          name: name,
          email: email,
          phone: phone,
          password: password,
          createdAt: createdAt,
          status: DeliveryStatus.assigned,
        );
    }
  }
}
