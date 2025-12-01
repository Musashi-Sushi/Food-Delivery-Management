import 'package:flutter/material.dart';
import 'package:food/rider/data/dummy_data.dart';
import 'package:food/rider/models/models.dart';
import 'package:food/rider/theme/app_colors.dart';

class PickupPage extends StatelessWidget {
  const PickupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cross = MediaQuery.of(context).size.width > 1200 ? 3 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          child: Text(
            'Ready for Pickup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: GridView.count(
              crossAxisCount: cross,
              childAspectRatio: 3.2,
              padding: const EdgeInsets.all(8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: assignedDeliveries.map((d) => _PickupCard(delivery: d)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickupCard extends StatelessWidget {
  final Delivery delivery;
  const _PickupCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: AppColors.primaryOrange,
            child: const Icon(Icons.store, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order #${delivery.orderId}", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text("Items: 3  •  Fee: \$8.50", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Ready'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {},
            child: const Text('Pickup'),
          ),
        ],
      ),
    );
  }
}
