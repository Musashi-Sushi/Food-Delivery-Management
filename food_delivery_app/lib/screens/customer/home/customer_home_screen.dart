import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/restaurant/restaurant.dart';
import '../../../models/restaurant/category.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../services/location/location_service.dart';
import '../cart/cart_screen.dart';
import '../restaurant/restaurant_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/track_order_screen.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/search_bar.dart';
import '../../../providers/order_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen>
    with TickerProviderStateMixin {
  final _locationService = LocationService();
  AppLocation? _userLocation;

  String _searchQuery = '';
  Category? _selectedCategory;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _headerController;

  bool _dataLoaded = false;
  String? _lastSeenOrderId;
  String? _lastCancelledOrderId;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadLocation();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _headerController.forward();
  }

  Future<void> _loadLocation() async {
    _userLocation = await _locationService.getCurrentLocation();
    if (mounted) setState(() {});
  }

  List<Restaurant> _getFilteredRestaurants(List<Restaurant> allRestaurants) {
    var filtered = allRestaurants.where((restaurant) {
      final query = _searchQuery.toLowerCase();
      final matchesName = restaurant.name.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == null
          ? true
          : restaurant.categories.any((c) => c.id == _selectedCategory!.id);
      return matchesName && matchesCategory;
    }).toList();

    return filtered;
  }

  List<Category> _getAllCategories(List<Restaurant> restaurants) {
    final categoriesSet = <Category>{};
    for (final restaurant in restaurants) {
      categoriesSet.addAll(restaurant.categories);
    }
    final categories = categoriesSet.toList();
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightPeachBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.lightPeachBackground,
        title: FadeTransition(
          opacity: _headerController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              Text(
                'Delicious food near you',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Colors.grey[600],
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.primaryOrange),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Consumer(
              builder: (context, ref, _) {
                final cart = ref.watch(cartProvider);
                final count = cart.totalItems;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primaryOrange,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryOrange,
                                    AppColors.primaryOrange.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: restaurantsAsync.when(
        data: (allRestaurants) {
          if (!_dataLoaded) {
            _dataLoaded = true;
            _fadeController.reset();
            _slideController.reset();
            _fadeController.forward();
            _slideController.forward();
          }

          final filteredRestaurants = _getFilteredRestaurants(allRestaurants);
          final allCategories = _getAllCategories(allRestaurants);

          return Stack(
            children: [
              FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _slideController,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: HomeSearchBar(
                          hintText: 'Search restaurants',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildCategoriesSection(allCategories),
                      const SizedBox(height: 28),
                      _buildRestaurantsHeader(filteredRestaurants),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredRestaurants.isEmpty
                            ? _buildEmptyState(context)
                            : _buildRestaurantList(
                                context,
                                filteredRestaurants,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Consumer(
                  builder: (context, ref, child) {
                    final activeOrderAsync = ref.watch(
                      currentCustomerOrderProvider,
                    );
                    return activeOrderAsync.when(
                      data: (doc) {
                        if (doc == null) return const SizedBox.shrink();

                        final data = doc.data() ?? <String, dynamic>{};
                        final orderId = doc.id;
                        final status = (data['status'] as String? ?? 'pending');
                        final deliveryStatus =
                            (data['delivery_status'] as String? ?? '');

                        final isTerminalStatus =
                            status == 'completed' || status == 'delivered';
                        final isDelivered = deliveryStatus == 'delivered';
                        final isCancelled =
                            status == 'cancelled' || status == 'rejected';
                        final reviewed =
                            (data['customer_reviewed'] as bool?) ?? false;

                        // Show delivered dialog with rating
                        if (isTerminalStatus && isDelivered && !reviewed) {
                          if (_lastSeenOrderId != orderId) {
                            _lastSeenOrderId = orderId;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  int rating = 0;
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: Container(
                                          width: 360,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                Colors.grey.shade50,
                                              ],
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TweenAnimationBuilder<double>(
                                                tween: Tween(begin: 0, end: 1),
                                                duration: const Duration(
                                                  milliseconds: 600,
                                                ),
                                                curve: Curves.elasticOut,
                                                builder: (context, val, child) {
                                                  return Transform.scale(
                                                    scale: val,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .green
                                                                    .shade400,
                                                                Colors
                                                                    .green
                                                                    .shade600,
                                                              ],
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 20,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  8,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 48,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Order Delivered!',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.grey.shade900,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Rate your experience with the restaurant',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(5, (i) {
                                                  final idx = i + 1;
                                                  final filled = rating >= idx;
                                                  return IconButton(
                                                    onPressed: () =>
                                                        setDialogState(
                                                          () => rating = idx,
                                                        ),
                                                    icon: Icon(
                                                      filled
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                    ),
                                                    color: Colors.amber,
                                                    iconSize: 32,
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: rating == 0
                                                      ? null
                                                      : () async {
                                                          final custId =
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid;
                                                          final restId =
                                                              (data['restaurant_id']
                                                                  as String?) ??
                                                              '';
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'reviews',
                                                              )
                                                              .add({
                                                                'restaurant_id':
                                                                    restId,
                                                                'customer_id':
                                                                    custId,
                                                                'order_id':
                                                                    orderId,
                                                                'rating':
                                                                    rating,
                                                                'created_at':
                                                                    FieldValue.serverTimestamp(),
                                                              });
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'orders',
                                                              )
                                                              .doc(orderId)
                                                              .update({
                                                                'customer_reviewed':
                                                                    true,
                                                              });
                                                          if (mounted)
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                        },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primaryOrange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Submit Rating',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            });
                          }
                          return const SizedBox.shrink();
                        }

                        // Show cancelled dialog
                        if (isCancelled) {
                          if (_lastCancelledOrderId != orderId) {
                            _lastCancelledOrderId = orderId;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      width: 320,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Colors.grey.shade50,
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            curve: Curves.elasticOut,
                                            builder: (context, val, child) {
                                              return Transform.scale(
                                                scale: val,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.red.shade400,
                                                        Colors.red.shade600,
                                                      ],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red
                                                            .withOpacity(0.3),
                                                        blurRadius: 20,
                                                        offset: const Offset(
                                                          0,
                                                          8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.white,
                                                    size: 48,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'Order Cancelled',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.grey.shade900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            status == 'rejected'
                                                ? 'Your order was rejected by the restaurant. If you paid online, you\'ll be refunded automatically shortly.'
                                                : 'Your order has been cancelled. If you paid online, you\'ll be refunded automatically shortly.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                'Okay',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
                          }
                          return const SizedBox.shrink();
                        }

                        if (isTerminalStatus || isDelivered) {
                          return const SizedBox.shrink();
                        }

                        String title;
                        String subtitle;
                        double progress;
                        IconData icon;

                        if (status == 'pending') {
                          title = 'Waiting for restaurant to accept';
                          subtitle =
                              'We\'ll notify you once the restaurant responds.';
                          icon = Icons.access_time;
                          progress = 0.15;
                        } else if (status == 'accepted') {
                          title = 'Your order has been accepted!';
                          subtitle =
                              'Restaurant is getting ready and a rider will be assigned.';
                          icon = Icons.restaurant_menu;
                          progress = 0.3;
                        } else if (status == 'preparing') {
                          title = 'Restaurant is preparing your food';
                          subtitle = 'Estimated time ~30 minutes.';
                          icon = Icons.local_dining;
                          progress = 0.5;
                        } else if (status == 'ready' &&
                            deliveryStatus != 'onTheWay') {
                          title = 'Order is ready for pickup';
                          subtitle = 'Waiting for rider to pick up your order.';
                          icon = Icons.store_mall_directory;
                          progress = 0.7;
                        } else if (deliveryStatus == 'onTheWay') {
                          title = 'Your order is on the way';
                          subtitle = 'Rider is heading to your address.';
                          icon = Icons.delivery_dining;
                          progress = 0.9;
                        } else {
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TrackOrderScreen(),
                                  ),
                                );
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
                                            color: AppColors.primaryOrange
                                                .withOpacity(0.1),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[700],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: Colors.grey[200],
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
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
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading restaurants...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(allRestaurantsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> allCategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.primaryOrange.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildCategoryChip(
                  label: 'All',
                  icon: Icons.restaurant_menu_rounded,
                  selected: _selectedCategory == null,
                  onSelected: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
              ),
              ...allCategories.asMap().entries.map((entry) {
                final category = entry.value;
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildAnimatedCategoryChip(
                    category: category,
                    selected: _selectedCategory?.id == category.id,
                    onSelected: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    delayMs: 50 + (index * 30),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantsHeader(List<Restaurant> filteredRestaurants) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryOrange,
                AppColors.primaryOrange.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _selectedCategory != null
              ? '${_selectedCategory!.name} Restaurants'
              : 'All Restaurants',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${filteredRestaurants.length} found',
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryOrange.withOpacity(0.85),
                    ],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : Colors.grey.withOpacity(0.2),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.primaryOrange,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.darkText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'burgers':
        return Icons.lunch_dining_rounded;
      case 'sushi':
        return Icons.set_meal_rounded;
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Widget _buildAnimatedCategoryChip({
    required Category category,
    required bool selected,
    required VoidCallback onSelected,
    required int delayMs,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delayMs)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return _buildCategoryChip(
          label: category.name,
          icon: _getCategoryIcon(category.name),
          selected: selected,
          onSelected: onSelected,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _fadeController.drive(Tween<double>(begin: 0.8, end: 1.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.peach, AppColors.peach.withOpacity(0.5)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No restaurants found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Try adjusting your search or filters to find what you\'re looking for.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantList(
    BuildContext context,
    List<Restaurant> filteredRestaurants,
  ) {
    return ListView.separated(
      itemCount: filteredRestaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final restaurant = filteredRestaurants[index];
        double? distanceKm;
        if (_userLocation != null) {
          distanceKm = _locationService.distanceInKm(
            _userLocation!.latitude,
            _userLocation!.longitude,
            restaurant.latitude,
            restaurant.longitude,
          );
        }
        return _buildAnimatedRestaurantCard(
          restaurant: restaurant,
          distanceKm: distanceKm,
          delayMs: index * 50,
        );
      },
    );
  }

  Widget _buildAnimatedRestaurantCard({
    required Restaurant restaurant,
    required double? distanceKm,
    required int delayMs,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delayMs)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return ScaleTransition(
          scale: _slideController.drive(Tween<double>(begin: 0.9, end: 1.0)),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) =>
                      RestaurantDetailScreen(restaurant: restaurant),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ),
                      ),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: RestaurantCard(
              restaurant: restaurant,
              distanceKm: distanceKm,
            ),
          ),
        );
      },
    );
  }
}
