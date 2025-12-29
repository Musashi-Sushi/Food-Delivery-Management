import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/delivery_provider.dart';
import '../../../models/delivery/delivery.dart';
import '../../../services/firestore/order_service.dart';
import '../../../services/location/location_service.dart';
import '../profile/rider_profile_screen.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  int _selectedIndex = 0;
  int? _hoveredIndex;
  Timer? _simTimer;
  bool _simulating = false;

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final assignedAsync = ref.watch(assignedDeliveriesProvider);
    final completedAsync = ref.watch(completedDeliveriesProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryOrange,
                  child: const Icon(Icons.fastfood, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                ..._buildTopNavItems(isNarrow),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(assignedDeliveriesProvider);
                ref.invalidate(completedDeliveriesProvider);
              },
              child: Container(
                color: AppColors.lightPeachBackground,
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 12 : 28,
                  vertical: 18,
                ),
                child: _buildContent(
                  _selectedIndex,
                  isNarrow,
                  assignedAsync,
                  completedAsync,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    int idx,
    bool isNarrow,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>> assignedAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    completedAsync,
  ) {
    switch (idx) {
      case 0:
        return _dashboard(isNarrow, assignedAsync, completedAsync);
      case 1:
        return _pickup(assignedAsync);
      case 2:
        return _liveNav();
      case 3:
        return _completed(completedAsync);
      case 4:
        return const RiderProfileScreen();
      default:
        return _dashboard(isNarrow, assignedAsync, completedAsync);
    }
  }

  List<Widget> _buildTopNavItems(bool isNarrow) {
    final items = const [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.store_outlined, 'label': 'Pickup'},
      {'icon': Icons.navigation_outlined, 'label': 'Live Nav'},
      {'icon': Icons.check_circle_outline, 'label': 'Completed'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];
    return List.generate(items.length, (i) {
      final active = _selectedIndex == i;
      final hover = _hoveredIndex == i;
      final scale = active || hover ? 1.12 : 1.0;
      final bg = active
          ? AppColors.primaryOrange
          : hover
          ? AppColors.peach.withOpacity(0.35)
          : Colors.transparent;
      final fg = active ? AppColors.white : AppColors.darkText;
      return MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = i),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Row(
                children: [
                  Icon(items[i]['icon'] as IconData, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _dashboard(
    bool isNarrow,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>> assignedAsync,
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    completedAsync,
  ) {
    final assignedCount = assignedAsync.asData?.value.length ?? 0;
    final completedCount = completedAsync.asData?.value.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryOrange,
                AppColors.peach,
                AppColors.primaryOrange.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rider Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Track deliveries, start pickups and view recent activity.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withOpacity(0.95),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard('Assigned', '$assignedCount', AppColors.primaryOrange),
            _statCard('Completed', '$completedCount', Colors.green.shade600),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isNarrow ? 1 : 2,
                child: _panel(
                  'Assigned Deliveries',
                  assignedAsync.when(
                    data: (docs) => ListView.separated(
                      padding: const EdgeInsets.all(12),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final orderId = (data['order_id'] as String?) ?? '';
                        final status =
                            (data['status'] as String?) ?? 'assigned';
                        final lat =
                            (data['current_lat'] as num?)?.toDouble() ?? 0;
                        final lng =
                            (data['current_lng'] as num?)?.toDouble() ?? 0;
                        return _deliveryTile(
                          docId: docs[index].id,
                          orderId: orderId,
                          status: status,
                          lat: lat,
                          lng: lng,
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load')),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _panel(
                  'Recent Completed',
                  completedAsync.when(
                    data: (docs) => ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final orderId = (data['order_id'] as String?) ?? '';
                        final lat =
                            (data['current_lat'] as num?)?.toDouble() ?? 0;
                        final lng =
                            (data['current_lng'] as num?)?.toDouble() ?? 0;
                        return _completedTile(
                          orderId: orderId,
                          lat: lat,
                          lng: lng,
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Failed to load')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickup(
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>> assignedAsync,
  ) {
    final availableAsync = ref.watch(availableRequestsProvider);
    final docs = availableAsync.asData?.value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.peach,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Ready for Pickup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.peach.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${docs.length} ${docs.length == 1 ? 'request' : 'requests'}',
                  style: TextStyle(
                    color: AppColors.peach,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => ref.invalidate(availableRequestsProvider),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh requests',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: availableAsync.when(
              data: (_) => GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.8,
                  mainAxisExtent: 180, // Fixed height for cards
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data();
                  final orderId = (data['order_id'] as String?) ?? '';
                  final status = (data['status'] as String?) ?? 'requested';
                  final lat = (data['current_lat'] as num?)?.toDouble() ?? 0;
                  final lng = (data['current_lng'] as num?)?.toDouble() ?? 0;
                  final storeName =
                      (data['store_name'] as String?) ?? 'Restaurant';
                  final itemsCount = (data['items_count'] as int?) ?? 0;
                  final fee = (data['fee'] as num?)?.toDouble() ?? 0.0;

                  return _pickupCard(
                    docId: d.id,
                    orderId: orderId,
                    status: status,
                    lat: lat,
                    lng: lng,
                    storeName: storeName,
                    itemsCount: itemsCount,
                    fee: fee,
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              error: (_, __) => Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ensure Firestore index for deliveries(status) is created.',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveNav() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.navigation_outlined,
                          color: AppColors.primaryOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Live Navigation',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _mapPlaceholder(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _simulating
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade600.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Simulation Running',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _completed(
    AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    completedAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Completed Deliveries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: completedAsync.when(
              data: (docs) => docs.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No completed deliveries yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final orderId = (data['order_id'] as String?) ?? '';
                        final lat =
                            (data['current_lat'] as num?)?.toDouble() ?? 0;
                        final lng =
                            (data['current_lng'] as num?)?.toDouble() ?? 0;
                        return _completedTile(
                          orderId: orderId,
                          lat: lat,
                          lng: lng,
                        );
                      },
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              error: (_, __) => Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load completed deliveries',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.95), color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            ' ',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryTile({
    required String docId,
    required String orderId,
    required String status,
    required double lat,
    required double lng,
  }) {
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$orderId',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('ETA: --', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (status != 'delivered')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('deliveries')
                        .doc(docId)
                        .update({
                          'status': 'delivered',
                          'delivered_at': FieldValue.serverTimestamp(),
                        });
                    await OrderService().updateOrderFields(orderId, {
                      'delivery_status': 'delivered',
                      'status': 'delivered',
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as delivered')),
                      );
                    }
                  },
                  child: const Text('Deliver'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickupCard({
    required String docId,
    required String orderId,
    required String status,
    required double lat,
    required double lng,
    String storeName = 'Store',
    int itemsCount = 0,
    double fee = 0.0,
  }) {
    final Color accent = AppColors.primaryOrange;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    storeName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text('$itemsCount items'),
                        backgroundColor: AppColors.peach.withOpacity(0.12),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('\$${fee.toStringAsFixed(2)} fee'),
                        backgroundColor: AppColors.peach.withOpacity(0.12),
                      ),
                      const Spacer(),
                      Text(
                        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final riderId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (riderId == null) return;
                            final ok = await Delivery.tryAssignRider(
                              deliveryId: docId,
                              riderId: riderId,
                            );
                            if (!ok) {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Already accepted'),
                                    content: const Text(
                                      'This delivery was accepted by another rider.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection('deliveries')
                                .doc(docId)
                                .update({'status': 'onTheWay'});
                            await OrderService().updateOrderFields(orderId, {
                              'rider_id': riderId,
                              'delivery_status': 'onTheWay',
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Assigned to you'),
                                  backgroundColor: AppColors.primaryOrange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryOrange.withOpacity(0.12),
                child: const Icon(Icons.store, color: AppColors.primaryOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order #$orderId • $itemsCount items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.peach.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'ETA: --',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.peach.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${lat.toStringAsFixed(3)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${fee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () async {
                      final riderId = FirebaseAuth.instance.currentUser?.uid;
                      if (riderId == null) return;
                      final ok = await Delivery.tryAssignRider(
                        deliveryId: docId,
                        riderId: riderId,
                      );
                      if (!ok) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Already accepted'),
                              content: const Text(
                                'This delivery was accepted by another rider.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('deliveries')
                          .doc(docId)
                          .update({'status': 'onTheWay'});
                      await OrderService().updateOrderFields(orderId, {
                        'rider_id': riderId,
                        'delivery_status': 'onTheWay',
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Assigned to you'),
                            backgroundColor: AppColors.primaryOrange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completedTile({
    required String orderId,
    required double lat,
    required double lng,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Order #$orderId',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Text(
            'Delivered',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'requested':
        return Colors.grey.shade600;
      case 'onTheWay':
        return Colors.orange.shade600;
      case 'pickedUp':
        return Colors.blue.shade600;
      case 'delivered':
        return Colors.green.shade600;
      case 'assigned':
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _mapPlaceholder() {
    final assignedAsync = ref.watch(assignedDeliveriesProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: assignedAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(child: Text('No active delivery'));
          }
          final data = docs.first.data();
          final restaurantId = (data['restaurant_id'] as String?) ?? '';
          return FutureBuilder<AppLocation>(
            future: LocationService().getCurrentLocation(),
            builder: (context, destSnap) {
              if (!destSnap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                );
              }
              final dest = destSnap.data!;
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(restaurantId)
                    .get(),
                builder: (context, rSnap) {
                  if (!rSnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    );
                  }
                  final rData = rSnap.data!.data() ?? const {};
                  final rLat = (rData['latitude'] as num?)?.toDouble() ?? 0;
                  final rLng = (rData['longitude'] as num?)?.toDouble() ?? 0;
                  final url = _staticMapUrl(
                    rLat,
                    rLng,
                    dest.latitude,
                    dest.longitude,
                  );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text('Map unavailable')),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 3)),
        error: (_, __) => const Center(child: Text('Map unavailable')),
      ),
    );
  }

  String _staticMapUrl(double lat1, double lng1, double lat2, double lng2) {
    final apiKey = '57c34431871640f18620db0a61caec7d';
    final centerLat = (lat1 + lat2) / 2.0;
    final centerLng = (lng1 + lng2) / 2.0;
    final markers =
        'marker=lonlat:$lng1,$lat1;color:%2300bfff;size:large|lonlat:$lng2,$lat2;color:%23ff0000;size:large';
    final geometry =
        'geometry=polyline:$lng1,$lat1,$lng2,$lat2;linecolor:%230000ff;linewidth:3';
    return 'https://maps.geoapify.com/v1/staticmap?style=osm-carto&width=860&height=420&center=lonlat:$centerLng,$centerLat&zoom=13&$markers&$geometry&apiKey=$apiKey';
  }
}
