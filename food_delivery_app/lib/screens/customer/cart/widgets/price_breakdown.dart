import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../checkout_screen.dart';

class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.onClearCart,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onClearCart;

  @override
  Widget build(BuildContext context) {
    final total = subtotal; // For now, no delivery/fees.

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items ($itemCount)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: onClearCart,
                  child: const Text(
                    'Clear cart',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                      child: ElevatedButton(
                        onPressed: itemCount == 0
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen(),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
  }
}