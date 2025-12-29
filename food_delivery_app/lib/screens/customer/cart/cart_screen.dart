import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/order/cart.dart';
import '../../../providers/cart_provider.dart';
import 'widgets/cart_item_card.dart';
import 'widgets/price_breakdown.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Cart cart = ref.watch(cartProvider);
    final items = cart.items;
    final subtotal = cart.calculateTotal();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.lightPeachBackground,
        body: _buildDesktopLayout(context, cart, items, subtotal),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.lightPeachBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.lightPeachBackground,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkText,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Cart',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          centerTitle: false,
          actions: [
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _showClearCartDialog(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: items.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _animationController,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.1,
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                            child: CartItemCard(
                              cartItem: item,
                              onIncrease: () => ref
                                  .read(cartProvider.notifier)
                                  .incrementQuantity(item.id),
                              onDecrease: () => ref
                                  .read(cartProvider.notifier)
                                  .decrementQuantity(item.id),
                              onRemove: () => ref
                                  .read(cartProvider.notifier)
                                  .removeItem(item.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: PriceBreakdown(
                      itemCount: cart.totalItems,
                      subtotal: subtotal,
                      onClearCart: () => _showClearCartDialog(context),
                    ),
                  ),
                ],
              ),
      );
    }
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Cart cart,
    List items,
    double subtotal,
  ) {
    return Row(
      children: [
        Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AppColors.peach.withOpacity(0.05)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightPeachBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.peach.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.darkText,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Shopping Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: AppColors.darkText,
                        letterSpacing: -1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryOrange.withOpacity(0.15),
                              AppColors.peach.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Divider(
                  color: AppColors.peach.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 24),
              if (items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Clear Cart',
                    color: Colors.red,
                    onPressed: () => _showClearCartDialog(context),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState(context)
              : Row(
                  children: [
                    // Cart items list
                    Expanded(
                      flex: 3,
                      child: FadeTransition(
                        opacity: _animationController,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = items[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(0.2, 0),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Interval(
                                                index * 0.1,
                                                1.0,
                                                curve: Curves.easeOutCubic,
                                              ),
                                            ),
                                          ),
                                      child: CartItemCard(
                                        cartItem: item,
                                        onIncrease: () => ref
                                            .read(cartProvider.notifier)
                                            .incrementQuantity(item.id),
                                        onDecrease: () => ref
                                            .read(cartProvider.notifier)
                                            .decrementQuantity(item.id),
                                        onRemove: () => ref
                                            .read(cartProvider.notifier)
                                            .removeItem(item.id),
                                      ),
                                    ),
                                  );
                                }, childCount: items.length),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Order summary sidebar
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: AppColors.darkText,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildSummaryRow(
                                  'Subtotal',
                                  '\$${subtotal.toStringAsFixed(2)}',
                                  false,
                                ),
                                const SizedBox(height: 16),
                                _buildSummaryRow(
                                  'Tax',
                                  '\$${(subtotal * 0.08).toStringAsFixed(2)}',
                                  false,
                                ),
                                const SizedBox(height: 24),
                                Divider(color: Colors.grey[300], thickness: 1),
                                const SizedBox(height: 24),
                                _buildSummaryRow(
                                  'Total',
                                  '\$${(subtotal + (subtotal * 0.08)).toStringAsFixed(2)}',
                                  true,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                // Promo code field
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.lightPeachBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.peach.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Promo code',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.local_offer_outlined,
                                        color: Colors.grey[500],
                                        size: 20,
                                      ),
                                      suffixIcon: TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: AppColors.primaryOrange,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Checkout button
                                PriceBreakdown(
                                  itemCount: cart.totalItems,
                                  subtotal: subtotal,
                                  onClearCart: () =>
                                      _showClearCartDialog(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isBold, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.darkText : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 24 : 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isHighlighted
                ? Colors.green
                : isBold
                ? AppColors.primaryOrange
                : AppColors.darkText,
            letterSpacing: isBold ? -0.5 : 0,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Cart?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: ScaleTransition(
          scale: _animationController.drive(
            Tween<double>(begin: 0.8, end: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.peach.withOpacity(0.5),
                      AppColors.peach.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: AppColors.primaryOrange.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Add some delicious items to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.restaurant_menu_rounded),
                label: const Text('Browse Menu'),
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.primaryOrange.withOpacity(0.5),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            return AppColors.primaryOrange.withOpacity(0.8);
                          }
                          return AppColors.primaryOrange;
                        },
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
