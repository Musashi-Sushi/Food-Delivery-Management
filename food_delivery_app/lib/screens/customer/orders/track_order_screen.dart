import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/order_provider.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  static const Duration _initialEta = Duration(minutes: 30);
  Duration _remaining = _initialEta;
  Timer? _timer;
  String? _lastStatus;
  bool _takingLonger = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startOrResetTimer(String currentStatus) {
    if (_lastStatus != currentStatus) {
      _remaining = _initialEta;
      _takingLonger = false;
      _lastStatus = currentStatus;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            // Status did not change within the window.
            _takingLonger = true;
            _remaining = _initialEta; // Restart countdown.
          }
        });
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m <= 0 && s <= 0) return '0:00';
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(currentCustomerOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Track your order')),
      backgroundColor: AppColors.lightPeachBackground,
      body: activeOrderAsync.when(
        data: (doc) {
          if (doc == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Once you place an order, you\'ll be able to track it here in real-time.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = doc.data() ?? <String, dynamic>{};
          final status = (data['status'] as String? ?? 'pending');
          final deliveryStatus = (data['delivery_status'] as String? ?? '');
          final total = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          final createdAtField = data['created_at'];
          DateTime? createdAt;
          if (createdAtField is Timestamp) {
            createdAt = createdAtField.toDate();
          }

          _startOrResetTimer(status);

          final steps = _buildSteps(status, deliveryStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, total, createdAt),
                const SizedBox(height: 24),
                _buildEtaCard(),
                const SizedBox(height: 24),
                Text(
                  'Order progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildTimeline(context, steps),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load order: $error',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double total, DateTime? createdAt) {
    final createdText = createdAt == null
        ? ''
        : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order in progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (createdText.isNotEmpty)
                    Text(
                      'Placed at $createdText',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaCard() {
    final etaText = _formatDuration(_remaining);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer, color: AppColors.primaryOrange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _takingLonger
                        ? 'Taking longer than expected'
                        : 'Estimated time to delivery',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _takingLonger
                        ? 'Hang tight, your order is almost there.'
                        : 'This is an approximate time based on typical orders.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              etaText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  List<_OrderStep> _buildSteps(String status, String deliveryStatus) {
    // Define the full journey.
    final steps = <_OrderStep>[
      const _OrderStep(
        id: 'pending',
        title: 'Order placed',
        description: 'We have received your order details.',
      ),
      const _OrderStep(
        id: 'accepted',
        title: 'Restaurant accepted',
        description: 'Restaurant has confirmed your order.',
      ),
      const _OrderStep(
        id: 'preparing',
        title: 'Preparing your food',
        description: 'Chefs are cooking your meal fresh.',
      ),
      const _OrderStep(
        id: 'ready',
        title: 'Ready for pickup',
        description: 'Order is ready at the restaurant.',
      ),
      const _OrderStep(
        id: 'onTheWay',
        title: 'Rider on the way',
        description: 'Your order is on its way to you.',
      ),
      const _OrderStep(
        id: 'delivered',
        title: 'Delivered',
        description: 'Enjoy your meal!',
      ),
    ];

    // Determine which step is current based on status + deliveryStatus.
    String currentId;
    if (status == 'pending') {
      currentId = 'pending';
    } else if (status == 'accepted') {
      currentId = 'accepted';
    } else if (status == 'preparing') {
      currentId = 'preparing';
    } else if (status == 'ready' && deliveryStatus != 'onTheWay') {
      currentId = 'ready';
    } else if (deliveryStatus == 'onTheWay') {
      currentId = 'onTheWay';
    } else if (status == 'completed' || status == 'delivered') {
      currentId = 'delivered';
    } else if (status == 'cancelled' || status == 'rejected') {
      // For cancelled / rejected, we still show steps, but mark last as cancelled.
      currentId = 'pending';
    } else {
      currentId = 'pending';
    }

    bool reachedCurrent = false;
    return steps.map((s) {
      if (s.id == currentId) {
        reachedCurrent = true;
        return s.copyWith(isCurrent: true, isCompleted: false);
      } else if (!reachedCurrent) {
        return s.copyWith(isCompleted: true, isCurrent: false);
      } else {
        return s.copyWith(isCompleted: false, isCurrent: false);
      }
    }).toList();
  }

  Widget _buildTimeline(BuildContext context, List<_OrderStep> steps) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            for (int i = 0; i < steps.length; i++)
              _buildTimelineRow(
                context,
                steps[i],
                isLast: i == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    _OrderStep step, {
    required bool isLast,
  }) {
    final color = step.isCompleted
        ? Colors.green
        : step.isCurrent
        ? AppColors.primaryOrange
        : Colors.grey[400]!;

    final icon = step.isCompleted
        ? Icons.check_circle
        : step.isCurrent
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        Column(
          children: [
            Icon(icon, color: color, size: 20),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: step.isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: step.isCurrent
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStep {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isCurrent;

  const _OrderStep({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  _OrderStep copyWith({bool? isCompleted, bool? isCurrent}) {
    return _OrderStep(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
