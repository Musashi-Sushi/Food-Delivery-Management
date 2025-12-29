import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user/restaurant_owner.dart';
import '../../../models/user/user.dart' as domain_user;
import '../../../models/enums/order_status.dart';
import '../../../models/enums/delivery_status.dart';
import '../../../models/delivery/delivery.dart';

final _ownerProvider = FutureProvider<RestaurantOwner?>((ref) async {
  final u = await domain_user.User.getCurrentDomainUser();
  if (u is RestaurantOwner) return u;
  return null;
});

final _restaurantIdProvider = FutureProvider<String?>((ref) async {
  final uid = (await ref.watch(_ownerProvider.future))?.id;
  if (uid == null) return null;
  final snap = await FirebaseFirestore.instance
      .collection('restaurants')
      .where('owner_id', isEqualTo: uid)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return snap.docs.first.id;
});

final _ordersProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((
      ref,
    ) async* {
      final rid = await ref.watch(_restaurantIdProvider.future);
      if (rid == null) {
        yield [];
        return;
      }
      yield* FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant_id', isEqualTo: rid)
          .snapshots()
          .map((s) {
            final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              s.docs,
            );
            docs.sort((a, b) {
              final at = a.data()['created_at'];
              final bt = b.data()['created_at'];
              final ad = at is Timestamp ? at.toDate() : DateTime(1970);
              final bd = bt is Timestamp ? bt.toDate() : DateTime(1970);
              return bd.compareTo(ad);
            });
            return docs;
          });
    });

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});
  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  String _dateFilter = 'Today';
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_ordersProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Orders',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ordersAsync.when(
              data: (docs) {
                final counts = _computeCounts(docs);
                return Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primaryOrange,
                      unselectedLabelColor: Colors.black87,
                      indicatorColor: AppColors.primaryOrange,
                      tabs: [
                        _tabWithBadge(
                          'Incoming',
                          counts['incoming'] ?? 0,
                          Colors.redAccent,
                        ),
                        _tabWithBadge(
                          'Active',
                          counts['active'] ?? 0,
                          Colors.amber,
                        ),
                        const Tab(
                          icon: Icon(Icons.check_circle_outline),
                          text: 'Completed',
                        ),
                        const Tab(
                          icon: Icon(Icons.cancel_outlined),
                          text: 'Cancelled/Rejected',
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const TabBar(
                tabs: [
                  Tab(text: 'Incoming'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled/Rejected'),
                ],
              ),
              error: (_, __) => const TabBar(
                tabs: [
                  Tab(text: 'Incoming'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled/Rejected'),
                ],
              ),
            ),
          ),
        ),
        body: ordersAsync.when(
          data: (docs) {
            final grouped = _groupOrders(docs);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_ordersProvider);
              },
              child: TabBarView(
                children: [
                  _incomingTab(grouped['incoming'] ?? []),
                  _activeTab(grouped['active'] ?? []),
                  _completedTab(grouped['completed'] ?? []),
                  _cancelledTab(grouped['cancelled'] ?? []),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Failed to load orders')),
        ),
      ),
    );
  }

  Map<String, int> _computeCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int incoming = 0, active = 0;
    for (final d in docs) {
      final s = (d.data()['status'] as String?) ?? '';
      if (s == 'pending') incoming++;
      if (s == 'accepted' || s == 'preparing' || s == 'ready') active++;
    }
    return {'incoming': incoming, 'active': active};
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final g = {
      'incoming': <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      'active': <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      'completed': <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      'cancelled': <QueryDocumentSnapshot<Map<String, dynamic>>>[],
    };
    for (final d in docs) {
      final s = (d.data()['status'] as String?) ?? '';
      switch (s) {
        case 'pending':
          g['incoming']!.add(d);
          break;
        case 'accepted':
        case 'preparing':
        case 'ready':
          g['active']!.add(d);
          break;
        case 'delivered':
          g['completed']!.add(d);
          break;
        case 'cancelled':
        case 'rejected':
          g['cancelled']!.add(d);
          break;
        default:
          g['active']!.add(d);
      }
    }
    return g;
  }

  Tab _tabWithBadge(String label, int count, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _incomingTab(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No incoming orders',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final data = docs[i].data();
        final id = docs[i].id;
        final cust = (data['customer_name'] as String?) ?? '';
        final ts = data['created_at'];
        final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
        final items = (data['items'] as List?) ?? [];
        final total = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #$id',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.primaryOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cust,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  items
                      .map(
                        (e) =>
                            '${e['quantity']}x ${e['menu_item_name'] ?? e['menu_item_id']}',
                      )
                      .join(', '),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Total: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Accept Order'),
                        onPressed: () async {
                          final owner = await ref.read(_ownerProvider.future);
                          if (owner == null) return;
                          final o = await owner.viewOrderDetails(id);
                          if (o == null) return;
                          await o.updateStatus(OrderStatus.accepted);
                          await o.updateDeliveryStatus(DeliveryStatus.assigned);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Reject Order'),
                        onPressed: () async {
                          final owner = await ref.read(_ownerProvider.future);
                          if (owner == null) return;
                          final o = await owner.viewOrderDetails(id);
                          if (o == null) return;
                          await o.updateStatus(OrderStatus.cancelled);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
  }

  Widget _activeTab(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timelapse, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final data = docs[i].data();
        final id = docs[i].id;
        final cust = (data['customer_name'] as String?) ?? '';
        final status = (data['status'] as String?) ?? '';
        final items = (data['items'] as List?) ?? [];
        final statusColor = _statusColor(status);
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #$id • $cust',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  items
                      .map(
                        (e) =>
                            '${e['quantity']}x ${e['menu_item_name'] ?? e['menu_item_id']}',
                      )
                      .join(', '),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Update Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final options = _statusOptions(status);
                          if (options.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primaryOrange,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Waiting for rider',
                                style: TextStyle(
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            );
                          }
                          return DropdownButton<String>(
                            value: null,
                            hint: const Text('Change Status'),
                            items: options
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) async {
                              if (val == null) return;
                              final owner = await ref.read(
                                _ownerProvider.future,
                              );
                              if (owner == null) return;
                              final o = await owner.viewOrderDetails(id);
                              if (o == null) return;
                              if (val == 'Preparing') {
                                await o.updateStatus(OrderStatus.preparing);
                              } else if (val == 'Ready for Pickup') {
                                await o.updateStatus(OrderStatus.ready);
                                final rSnap = await FirebaseFirestore.instance
                                    .collection('restaurants')
                                    .doc(o.restaurantId)
                                    .get();
                                final rData = rSnap.data() ?? const {};
                                final lat =
                                    (rData['latitude'] as num?)?.toDouble() ??
                                    0;
                                final lng =
                                    (rData['longitude'] as num?)?.toDouble() ??
                                    0;
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
                              }
                            },
                            isExpanded: true,
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                            ),
                            underline: Container(
                              height: 2,
                              color: AppColors.primaryOrange,
                            ),
                          );
                        },
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
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<String> _statusOptions(String status) {
    if (status == 'accepted') return ['Preparing'];
    if (status == 'preparing') return ['Ready for Pickup'];
    return [];
  }

  Widget _completedTab(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final filtered = _applyCompletedFilters(docs);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by order # or customer name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _dateFilter,
                items: const [
                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                  DropdownMenuItem(
                    value: 'This Week',
                    child: Text('This Week'),
                  ),
                  DropdownMenuItem(
                    value: 'This Month',
                    child: Text('This Month'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom Range',
                    child: Text('Custom Range'),
                  ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  if (v == 'Custom Range') {
                    final start = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (start != null) {
                      final end = await showDatePicker(
                        context: context,
                        firstDate: start,
                        lastDate: DateTime(2100),
                        initialDate: start,
                      );
                      setState(() {
                        _dateFilter = v;
                        _customStart = start;
                        _customEnd = end ?? start;
                      });
                    }
                  } else {
                    setState(() {
                      _dateFilter = v;
                      _customStart = null;
                      _customEnd = null;
                    });
                  }
                },
                style: const TextStyle(color: AppColors.primaryOrange),
                underline: Container(height: 2, color: AppColors.primaryOrange),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No completed orders',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final data = filtered[i].data();
                    final id = filtered[i].id;
                    final cust = (data['customer_name'] as String?) ?? '';
                    final ts = data['created_at'];
                    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
                    final total =
                        (data['total_amount'] as num?)?.toDouble() ?? 0.0;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.done_all,
                          color: Colors.green,
                        ),
                        title: Text(
                          'Order #$id • $cust',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        onTap: () => _openReceipt(filtered[i]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyCompletedFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var list = docs
        .where((d) => (d.data()['status'] as String?) == 'delivered')
        .toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((d) {
        final cust =
            (d.data()['customer_name'] as String?)?.toLowerCase() ?? '';
        final id = d.id.toLowerCase();
        return cust.contains(q) || id.contains(q);
      }).toList();
    }
    DateTime start;
    DateTime end;
    final now = DateTime.now();
    if (_dateFilter == 'Today') {
      start = DateTime(now.year, now.month, now.day);
      end = now;
    } else if (_dateFilter == 'This Week') {
      start = now.subtract(const Duration(days: 7));
      end = now;
    } else if (_dateFilter == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = now;
    } else if (_dateFilter == 'Custom Range' &&
        _customStart != null &&
        _customEnd != null) {
      start = _customStart!;
      end = _customEnd!;
    } else {
      start = DateTime(now.year, now.month, 1);
      end = now;
    }
    list = list.where((d) {
      final ts = d.data()['created_at'];
      final dt = ts is Timestamp ? ts.toDate() : now;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
    return list;
  }

  void _openReceipt(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final id = doc.id;
    final cust = (data['customer_name'] as String?) ?? '';
    final items = (data['items'] as List?) ?? [];
    final total = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Text(
              'Receipt • Order #$id',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cust,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...items
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${e['quantity']}x ${e['menu_item_name'] ?? e['menu_item_id']}',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          Text(
                            '\$${e['price']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelledTab(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No cancelled or rejected orders',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final data = docs[i].data();
        final id = docs[i].id;
        final cust = (data['customer_name'] as String?) ?? '';
        final reasonStatus = (data['status'] as String?) ?? '';
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
            title: Text(
              'Order #$id • $cust',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: $reasonStatus',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      },
    );
  }
}
