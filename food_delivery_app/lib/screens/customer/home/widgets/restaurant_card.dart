import 'package:flutter/material.dart';

import '../../../../models/restaurant/restaurant.dart';
import '../../../../core/constants/app_colors.dart';

/// Card showing a restaurant preview.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant, this.distanceKm});

  final Restaurant restaurant;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            // Image section
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColors.peach,
                child: restaurant.imageUrl.isNotEmpty
                    ? Image.network(
                        restaurant.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.deliveryTimeMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km away',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      restaurant.cuisine,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
