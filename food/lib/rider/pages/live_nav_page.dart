import 'package:flutter/material.dart';
import 'package:food/rider/theme/app_colors.dart';
import 'package:food/rider/widgets/map_placeholder.dart';
import 'package:food/rider/widgets/panel_card.dart';

class LiveNavPage extends StatelessWidget {
  final bool simulating;
  final VoidCallback onToggleSim;
  const LiveNavPage({super.key, required this.simulating, required this.onToggleSim});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: PanelCard(
              title: 'Live Navigation (Simulation)',
              child: Column(
                children: [
                  Expanded(child: MapPlaceholder()),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [AppColors.lightPeach, AppColors.peach],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        simulating
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Simulation Running',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                ),
                                onPressed: onToggleSim,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Simulate'),
                              ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.navigation),
                              label: const Text('Route'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Details'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
