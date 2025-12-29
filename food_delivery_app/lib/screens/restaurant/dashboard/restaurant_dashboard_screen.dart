import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/constants/menu_types.dart';
import 'package:food_delivery_app/screens/restaurant/orders/owner_orders_screen.dart';
import 'package:food_delivery_app/screens/restaurant/menu/owner_menu_screen.dart';
import 'package:food_delivery_app/models/delivery/delivery.dart';
import '../../../core/constants/app_colors.dart';
import '../settings/owner_settings_screen.dart';
import '../../../models/enums/order_status.dart';
import '../../../models/enums/delivery_status.dart';
import '../../../models/restaurant/restaurant.dart';
import '../../../models/restaurant/menu_item.dart';
import '../../../models/user/restaurant_owner.dart';
import '../../../models/user/user.dart' as domain_user;

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  final Restaurant? restaurant;
  const RestaurantDashboardScreen({super.key, this.restaurant});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

final _currentOwnerProvider = FutureProvider<RestaurantOwner?>((ref) async {
  final u = await domain_user.User.getCurrentDomainUser();
  if (u is RestaurantOwner) return u;
  return null;
});

final _ownerRestaurantProvider = FutureProvider<Restaurant?>((ref) async {
  // Allow injected restaurant via a provider override for flexibility.
  final injected = ref.watch(injectedRestaurantProvider);
  if (injected != null) return injected;
  final owner = await ref.watch(_currentOwnerProvider.future);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (owner == null || uid == null) return null;
  final snap = await FirebaseFirestore.instance
      .collection('restaurants')
      .where('owner_id', isEqualTo: uid)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  final data = snap.docs.first.data();
  data['restaurant_id'] ??= snap.docs.first.id;
  return Restaurant.fromFirestore(data);
});

final injectedRestaurantProvider = Provider<Restaurant?>((ref) => null);

Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _ordersStream(
  String restaurantId, {
  int limit = 10,
}) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant_id', isEqualTo: restaurantId)
      .snapshots()
      .map((s) {
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          s.docs,
        );
        docs.sort((a, b) {
          final at = a.data()['created_at'];
          final bt = b.data()['created_at'];
          final ad = at is Timestamp
              ? at.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bd = bt is Timestamp
              ? bt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
        return docs.take(limit).toList();
      });
}

final _ordersFeedProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) async* {
      final restaurant = await ref.watch(_ownerRestaurantProvider.future);
      if (restaurant == null) {
        yield [];
        return;
      }
      yield* _ordersStream(restaurant.id, limit: 10);
    });

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _todayOrdersStream(
  String restaurantId,
) {
  final start = _startOfDay(DateTime.now());
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant_id', isEqualTo: restaurantId)
      .snapshots()
      .map((s) {
        final docs = s.docs.where((d) {
          final ts = d.data()['created_at'];
          final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
          return !dt.isBefore(start);
        }).toList();
        return docs;
      });
}

final _todayOrdersProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) async* {
      final restaurant = await ref.watch(_ownerRestaurantProvider.future);
      if (restaurant == null) {
        yield [];
        return;
      }
      yield* _todayOrdersStream(restaurant.id);
    });

final _reviewsProvider =
    StreamProvider.autoDispose<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
    >((ref) async* {
      final restaurant = await ref.watch(_ownerRestaurantProvider.future);
      if (restaurant == null) {
        yield [];
        return;
      }
      yield* FirebaseFirestore.instance
          .collection('reviews')
          .where('restaurant_id', isEqualTo: restaurant.id)
          .snapshots()
          .map((s) => s.docs);
    });

class _OwnerStats {
  final double todaysRevenue;
  final int activeOrders;
  final int completedToday;
  final double rating;
  final int reviewCount;
  const _OwnerStats({
    required this.todaysRevenue,
    required this.activeOrders,
    required this.completedToday,
    required this.rating,
    required this.reviewCount,
  });
}

String _formatNumber(num n) {
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write(',');
      count = 0;
    }
  }
  return buf.toString().split('').reversed.join();
}

_OwnerStats _computeStats(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> ordersToday,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews,
) {
  double revenue = 0;
  int active = 0;
  int completed = 0;
  for (final doc in ordersToday) {
    final data = doc.data();
    final status = (data['status'] as String?) ?? '';
    final delivery = (data['delivery_status'] as String?) ?? '';
    final amount = (data['total_amount'] is int)
        ? (data['total_amount'] as int).toDouble()
        : (data['total_amount'] as num?)?.toDouble() ?? 0.0;
    if (status == 'delivered' ||
        status == 'completed' ||
        delivery == 'delivered') {
      completed++;
      revenue += amount;
    } else if (status != 'cancelled' && status != 'rejected') {
      active++;
    }
  }
  double ratingSum = 0;
  for (final r in reviews) {
    final data = r.data();
    ratingSum += (data['rating'] as num?)?.toDouble() ?? 0.0;
  }
  final reviewCount = reviews.length;
  final rating = reviewCount == 0 ? 0.0 : (ratingSum / reviewCount);
  return _OwnerStats(
    todaysRevenue: revenue,
    activeOrders: active,
    completedToday: completed,
    rating: double.parse(rating.toStringAsFixed(1)),
    reviewCount: reviewCount,
  );
}

class _RestaurantDashboardScreenState
    extends ConsumerState<RestaurantDashboardScreen> {
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _scheduleAutoRefresh();
    });
  }

  void _scheduleAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() {
        _lastRefresh = DateTime.now();
      });
      return true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerAsync = ref.watch(_currentOwnerProvider);
    final restaurantAsync = ref.watch(_ownerRestaurantProvider);
    final ordersTodayAsync = ref.watch(_todayOrdersProvider);
    final reviewsAsync = ref.watch(_reviewsProvider);
    final feedAsync = ref.watch(_ordersFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.lightPeachBackground,
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ownerAsync.when(
                    data: (owner) => Text(
                      owner == null
                          ? 'Welcome back'
                          : 'Welcome back, ${owner.name}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.darkText),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: ordersTodayAsync.when(
                              data: (ordersToday) {
                                final stats = _computeStats(
                                  ordersToday,
                                  reviewsAsync.asData?.value ?? [],
                                );
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _statTile(
                                      'Today\'s Revenue',
                                      '\$${_formatNumber(stats.todaysRevenue)}',
                                      Icons.attach_money,
                                      AppColors.primaryOrange,
                                    ),
                                    _statTile(
                                      'Active Orders',
                                      '${stats.activeOrders}',
                                      Icons.receipt_long,
                                      Colors.blueGrey,
                                    ),
                                    _statTile(
                                      'Completed Today',
                                      '${stats.completedToday}',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                    _statTile(
                                      'Restaurant Rating',
                                      '${stats.rating} (${stats.reviewCount} reviews)',
                                      Icons.star,
                                      Colors.amber,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(height: 64),
                              error: (_, __) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _statTile(
                                    'Today\'s Revenue',
                                    '\$0',
                                    Icons.attach_money,
                                    AppColors.primaryOrange,
                                  ),
                                  _statTile(
                                    'Active Orders',
                                    '0',
                                    Icons.receipt_long,
                                    Colors.blueGrey,
                                  ),
                                  _statTile(
                                    'Completed Today',
                                    '0',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                  _statTile(
                                    'Restaurant Rating',
                                    '0.0★ (0 reviews)',
                                    Icons.star,
                                    Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(children: [_quickActions(context, restaurantAsync)]),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _liveOrdersFeed(context, feedAsync),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _salesCharts(context, ordersTodayAsync),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              final rAsync = ref.watch(_ownerRestaurantProvider);
              return rAsync.when(
                data: (r) => Text(
                  r?.name ?? 'Restaurant',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                loading: () => Text(
                  'Restaurant',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                error: (_, __) => Text(
                  'Restaurant',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _sidebarItem(
            context,
            Icons.dashboard_customize,
            'Dashboard',
            selected: true,
          ),
          _sidebarItem(
            context,
            Icons.receipt,
            'Orders',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerOrdersScreen()),
              );
            },
          ),
          _sidebarItem(
            context,
            Icons.restaurant_menu,
            'Menu',
            onTap: () {
              final rAsync = ref.read(_ownerRestaurantProvider);
              final r = rAsync.asData?.value;
              if (r == null || !r.isApproved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restaurant not approved yet')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OwnerMenuScreen(restaurant: r),
                ),
              );
            },
          ),

          _sidebarItem(
            context,
            Icons.settings,
            'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerSettingsScreen()),
              );
            },
          ),
          const Spacer(),
          Text(
            'Updated ${_lastRefresh.hour.toString().padLeft(2, '0')}:${_lastRefresh.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primaryOrange : AppColors.darkText,
      ),
      title: Text(label),
      selected: selected,
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Coming soon')));
          },
    );
  }

  Widget _statTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    AsyncValue<Restaurant?> restaurantAsync,
  ) {
    return Expanded(
      child: Row(
        children: [
          _actionButton(
            'Add New Menu Item',
            Icons.add_circle,
            () => _openAddItemDialog(context, restaurantAsync),
          ),
          const SizedBox(width: 12),
          _actionButton(
            'Mark Items Unavailable',
            Icons.block,
            () => _openToggleAvailabilityDialog(context, restaurantAsync),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _liveOrdersFeed(
    BuildContext context,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>> feedAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.live_tv, color: AppColors.primaryOrange),
                const SizedBox(width: 8),
                Text(
                  'Live Orders Feed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: feedAsync.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return const Center(child: Text('No recent orders'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final orderId = docs[index].id;
                      final status = (data['status'] as String?) ?? '';
                      final createdAt = (data['created_at'] is Timestamp)
                          ? (data['created_at'] as Timestamp).toDate()
                          : DateTime.now();
                      final items = (data['items'] as List?) ?? [];
                      final customerName =
                          (data['customer_name'] as String?) ?? '';
                      final totalAmount =
                          (data['total_amount'] as num?)?.toDouble() ?? 0.0;
                      final timeStr =
                          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                      final itemsStr = items
                          .map(
                            (e) => '${e['quantity']}x ${e['menu_item_name']}',
                          )
                          .join(', ');
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openOrderDetail(context, orderId, data),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.black12,
                                child: Text(
                                  timeStr,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Order #$orderId',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (customerName.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('• $customerName'),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      itemsStr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusChip(status),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Failed to load orders')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color c;
    IconData icon;
    String label;
    switch (status) {
      case 'pending':
        c = Colors.grey;
        icon = Icons.timer_outlined;
        label = 'Pending';
        break;
      case 'accepted':
        c = Colors.blueGrey;
        icon = Icons.assignment_turned_in_outlined;
        label = 'Accepted';
        break;
      case 'preparing':
        c = Colors.orange;
        icon = Icons.restaurant_menu;
        label = 'Preparing';
        break;
      case 'ready':
        c = Colors.teal;
        icon = Icons.inventory_2_outlined;
        label = 'Ready';
        break;
      case 'delivered':
        c = Colors.green;
        icon = Icons.local_shipping_outlined;
        label = 'Delivered';
        break;
      case 'cancelled':
      case 'rejected':
        c = Colors.redAccent;
        icon = Icons.cancel_outlined;
        label = status == 'cancelled' ? 'Cancelled' : 'Rejected';
        break;
      default:
        c = Colors.black54;
        icon = Icons.help_outline;
        label = status;
    }
    return Chip(
      avatar: Icon(icon, size: 18, color: c),
      label: Text(label),
      backgroundColor: c.withOpacity(0.12),
      shape: StadiumBorder(side: BorderSide(color: c.withOpacity(0.25))),
    );
  }

  void _openOrderDetail(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order #$orderId'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${(data['customer_name'] as String?) ?? ''}'),
              const SizedBox(height: 8),
              Text('Status: ${(data['status'] as String?) ?? ''}'),
              const SizedBox(height: 8),
              Text('Items:'),
              const SizedBox(height: 4),
              ...(((data['items'] as List?) ?? []).map<Widget>(
                (e) => Text(
                  '• ${e['quantity']}x ${e['menu_item_name']} @ ${e['price']}',
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if ((data['status'] as String?) == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    final owner = await ref.read(_currentOwnerProvider.future);
                    if (owner == null) return;
                    final o = await owner.viewOrderDetails(orderId);
                    if (o == null) return;
                    await o.updateStatus(OrderStatus.accepted);
                    await o.updateDeliveryStatus(DeliveryStatus.assigned);
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final owner = await ref.read(_currentOwnerProvider.future);
                    if (owner == null) return;
                    final o = await owner.viewOrderDetails(orderId);
                    if (o == null) return;
                    await o.updateStatus(OrderStatus.cancelled);
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
          Builder(
            builder: (_) {
              final s = (data['status'] as String?) ?? '';
              final d = (data['delivery_status'] as String?) ?? '';
              if (s == 'cancelled' || s == 'rejected' || s == 'delivered') {
                return const SizedBox.shrink();
              }
              final buttons = <Widget>[];
              if (s == 'pending' || s == 'accepted') {
                buttons.add(
                  TextButton(
                    onPressed: () async {
                      final owner = await ref.read(
                        _currentOwnerProvider.future,
                      );
                      if (owner == null) return;
                      final o = await owner.viewOrderDetails(orderId);
                      if (o == null) return;
                      await o.updateStatus(OrderStatus.preparing);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Text('Set Preparing'),
                  ),
                );
                buttons.add(const SizedBox(width: 8));
              }
              if (s == 'preparing') {
                buttons.add(
                  TextButton(
                    onPressed: () async {
                      final owner = await ref.read(
                        _currentOwnerProvider.future,
                      );
                      if (owner == null) return;
                      final o = await owner.viewOrderDetails(orderId);
                      if (o == null) return;
                      await o.updateStatus(OrderStatus.ready);
                      final rSnap = await FirebaseFirestore.instance
                          .collection('restaurants')
                          .doc(o.restaurantId)
                          .get();
                      final rData = rSnap.data() ?? const {};
                      final lat = (rData['latitude'] as num?)?.toDouble() ?? 0;
                      final lng = (rData['longitude'] as num?)?.toDouble() ?? 0;
                      final delivery = await Delivery.create(
                        orderId: o.id,
                        restaurantId: o.restaurantId,
                        customerId: o.customerId,
                        riderId: null,
                        currentLat: lat,
                        currentLng: lng,
                        status: DeliveryStatus.requested,
                      );
                      final storeName =
                          (rData['name'] as String?) ?? 'Restaurant';
                      final itemsCount = o.items.fold<int>(
                        0,
                        (sum, it) => sum + it.quantity,
                      );
                      await delivery.updateFields({
                        'store_name': storeName,
                        'items_count': itemsCount,
                        'fee': o.totalAmount,
                      });
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Text('Set Ready'),
                  ),
                );
                buttons.add(const SizedBox(width: 8));
              }
              if (s == 'ready' && d != 'onTheWay') {
                buttons.add(
                  TextButton(
                    onPressed: () async {
                      final owner = await ref.read(
                        _currentOwnerProvider.future,
                      );
                      if (owner == null) return;
                      final o = await owner.viewOrderDetails(orderId);
                      if (o == null) return;
                      await o.updateDeliveryStatus(DeliveryStatus.onTheWay);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Text('Set On The Way'),
                  ),
                );
                buttons.add(const SizedBox(width: 8));
              }
              // Cancel available in non-terminal states
              if (s != 'cancelled' && s != 'rejected' && s != 'delivered') {
                buttons.add(
                  TextButton(
                    onPressed: () async {
                      final owner = await ref.read(
                        _currentOwnerProvider.future,
                      );
                      if (owner == null) return;
                      final o = await owner.viewOrderDetails(orderId);
                      if (o == null) return;
                      await o.updateStatus(OrderStatus.cancelled);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Text('Cancel Order'),
                  ),
                );
              }
              return Row(mainAxisSize: MainAxisSize.min, children: buttons);
            },
          ),
        ],
      ),
    );
  }

  Widget _salesCharts(
    BuildContext context,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    ordersTodayAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ordersTodayAsync.when(
          data: (docs) {
            final perHour = List<int>.filled(24, 0);
            for (final d in docs) {
              final data = d.data();
              final ts = data['created_at'];
              final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
              perHour[dt.hour] = perHour[dt.hour] + 1;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Sales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No sales yet today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkText.withOpacity(0.6),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 180,
                  child: _LineChart(
                    values: perHour.map((e) => e.toDouble()).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                _hourLabels(),
              ],
            );
          },
          loading: () => SizedBox(
            height: 120,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => SizedBox(
            height: 120,
            child: const Center(
              child: Text(
                'Failed to load charts',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hourLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final hour = i * 4;
        return Text(
          '${hour.toString().padLeft(2, '0')}:00',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        );
      }),
    );
  }

  Future<void> _openAddItemDialog(
    BuildContext context,
    AsyncValue<Restaurant?> restaurantAsync,
  ) async {
    final restaurant = restaurantAsync.asData?.value;
    if (restaurant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No restaurant found')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCatId = menu_categories.isNotEmpty
        ? menu_categories.first.id
        : null;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Menu Item'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: [
                    for (final c in menu_categories)
                      DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final owner = await ref.read(_currentOwnerProvider.future);
                if (owner == null) return;
                final item = MenuItem(
                  id: '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  categoryId: selectedCatId ?? '',
                  available: true,
                );
                await owner.addMenuItem(item);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openToggleAvailabilityDialog(
    BuildContext context,
    AsyncValue<Restaurant?> restaurantAsync,
  ) async {
    final restaurant = await ref.read(_ownerRestaurantProvider.future);
    if (restaurant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No restaurant found')));
      return;
    }
    final menu = await restaurant.getMenu();
    final states = {for (final m in menu) m.id: m.available};
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Toggle Availability'),
            content: SizedBox(
              width: 520,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: menu.length,
                itemBuilder: (context, i) {
                  final m = menu[i];
                  final v = states[m.id] ?? false;
                  return SwitchListTile(
                    title: Text(m.name),
                    subtitle: Text(m.categoryId),
                    value: v,
                    onChanged: (nv) async {
                      setState(() => states[m.id] = nv);
                      final owner = await ref.read(
                        _currentOwnerProvider.future,
                      );
                      if (owner != null) {
                        if (!nv) {
                          await owner.markItemOutOfStock(m.id);
                        } else {
                          await owner.updateMenuItem(m.id, available: true);
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> values;
  const _LineChart({required this.values});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(values),
      child: Container(color: Colors.transparent),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  _LineChartPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final maxV = (values.isEmpty)
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final stepX = size.width / (values.length - 1).clamp(1, double.infinity);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y =
          size.height - ((values[i] / (maxV == 0 ? 1 : maxV)) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
