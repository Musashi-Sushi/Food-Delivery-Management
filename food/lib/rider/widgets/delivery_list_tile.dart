import 'package:flutter/material.dart';
import 'package:food/rider/data/dummy_data.dart';
import 'package:food/rider/models/models.dart';
import 'package:food/rider/theme/app_colors.dart';

class DeliveryListTile extends StatelessWidget {
  final Delivery delivery;
  const DeliveryListTile({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(delivery.status);
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
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order #${delivery.orderId}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  "ETA: --  •  Rider: ${currentRider.fullName}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                delivery.status.name.toUpperCase(),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text("${delivery.currentLat.toStringAsFixed(4)}, ${delivery.currentLng.toStringAsFixed(4)}", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.onTheWay:
        return Colors.orange.shade600;
      case DeliveryStatus.pickedUp:
        return Colors.blue.shade600;
      case DeliveryStatus.delivered:
        return Colors.green.shade600;
      case DeliveryStatus.assigned:
      default:
        return Colors.grey.shade600;
    }
  }
}
