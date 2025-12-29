import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore/delivery_service.dart';

/// 1. Firestore `deliveries` collection reference
final deliveriesCollectionProvider =
    Provider<CollectionReference<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance.collection('deliveries'),
    );

/// 2. Current logged-in rider's UID
final currentRiderProvider = Provider<String?>(
  (ref) => FirebaseAuth.instance.currentUser?.uid,
);

/// 3. Generic provider used for filtering deliveries by status
final deliveriesByStatusProvider =
    StreamProvider.family<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>,
      String
    >((ref, status) {
      final riderId = ref.watch(currentRiderProvider);
      if (riderId == null) return const Stream.empty();

      final col = ref.watch(deliveriesCollectionProvider);

      return col
          .where('rider_id', isEqualTo: riderId)
          .where('status', isEqualTo: status)
          .snapshots()
          .map((s) => s.docs);
    });

/// 4. Assigned deliveries (all except "delivered")
final assignedDeliveriesProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
      final riderId = ref.watch(currentRiderProvider);
      if (riderId == null) return const Stream.empty();

      final col = ref.watch(deliveriesCollectionProvider);

      return col
          .where('rider_id', isEqualTo: riderId)
          .where('status', whereIn: ['assigned', 'pickedUp', 'onTheWay'])
          .snapshots()
          .map((s) => s.docs);
    });

/// 5. Completed deliveries (status == delivered)
final completedDeliveriesProvider = deliveriesByStatusProvider('delivered');

/// 6. Available delivery requests (unassigned deliveries)
final availableRequestsProvider = StreamProvider(
  (ref) => DeliveryService().streamAvailableRequests(),
);
