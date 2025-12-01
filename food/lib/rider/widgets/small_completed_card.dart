import 'package:flutter/material.dart';
import 'package:food/rider/models/models.dart';

class SmallCompletedCard extends StatelessWidget {
  final Delivery delivery;
  const SmallCompletedCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 88,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(
            "Order #${delivery.orderId}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            "${delivery.currentLat.toStringAsFixed(3)}, ${delivery.currentLng.toStringAsFixed(3)}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
