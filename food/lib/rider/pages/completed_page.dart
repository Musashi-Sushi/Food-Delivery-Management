import 'package:flutter/material.dart';
import 'package:food/rider/data/dummy_data.dart';
import 'package:food/rider/theme/app_colors.dart';
import 'package:food/rider/widgets/panel_card.dart';

class CompletedPage extends StatelessWidget {
  const CompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: completedDeliveries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = completedDeliveries[index];
                return _CompletedOrderTile(orderId: d.orderId, lat: d.currentLat, lng: d.currentLng);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedOrderTile extends StatelessWidget {
  final int orderId;
  final double lat;
  final double lng;
  const _CompletedOrderTile({required this.orderId, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.green.shade500,
            child: const Icon(Icons.check, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderId', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('Delivered', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
