import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the current customer's latest order
///
/// This listens to the orders collection and always returns the most recent
/// order document for the logged-in customer, or `null` if there isn't one.
///
final currentCustomerOrderProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection('orders')
          .where('customer_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(1)
          .snapshots()
          .map((snap) => snap.docs.isEmpty ? null : snap.docs.first);
    });
