import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/core/constants/app_colors.dart';
import 'package:food_delivery_app/screens/customer/orders/track_order_screen.dart';

class OrderStatusBanner extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> orderDoc;

  const OrderStatusBanner({required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    final data = orderDoc.data() ?? {};
    final status = data['status'] as String? ?? '';
    final deliveryStatus = data['delivery_status'] as String? ?? '';
    print('[Banner] status: $status, delivery: $deliveryStatus');

    if (status == 'delivered' && deliveryStatus == 'delivered') {
      print('[Banner] Order delivered, hiding banner');
      return const SizedBox.shrink();
    }

    // Map status to UI elements
    String title;
    String subtitle;
    double progress;
    IconData icon;

    switch (status) {
      case 'pending':
        title = 'Waiting for restaurant to accept';
        subtitle = 'We\'ll notify you once the restaurant responds.';
        icon = Icons.access_time;
        progress = 0.15;
        break;
      case 'accepted':
        title = 'Your order has been accepted!';
        subtitle = 'Restaurant is preparing your food.';
        icon = Icons.restaurant_menu;
        progress = 0.3;
        break;
      case 'preparing':
        title = 'Restaurant is preparing your food';
        subtitle = 'Estimated time ~30 minutes.';
        icon = Icons.local_dining;
        progress = 0.5;
        break;
      case 'ready':
        title = deliveryStatus == 'onTheWay'
            ? 'Your order is on the way'
            : 'Order is ready for pickup';
        subtitle = deliveryStatus == 'onTheWay'
            ? 'Rider is heading to your address.'
            : 'Waiting for rider to pick up your order.';
        icon = deliveryStatus == 'onTheWay'
            ? Icons.delivery_dining
            : Icons.store_mall_directory;
        progress = deliveryStatus == 'onTheWay' ? 0.9 : 0.7;
        break;
      case 'cancelled':
      case 'rejected':
        title = 'Order was cancelled';
        subtitle =
            'If you paid online, you\'ll be refunded automatically shortly.';
        icon = Icons.cancel_outlined;
        progress = 1.0;
        break;
      default:
        title = 'Order update';
        subtitle = 'Your order status is: $status';
        icon = Icons.info_outline;
        progress = 0.3;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TrackOrderScreen()));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
