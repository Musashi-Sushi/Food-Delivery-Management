import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/screens/customer/home/customer_home_screen.dart';
import 'package:food_delivery_app/screens/restaurant/selector/owner_restaurant_selector_screen.dart';
import 'package:food_delivery_app/screens/rider/dashboard/rider_dashboard_screen.dart';
import '../../models/user/user.dart' as domain_user;
import '../../models/user/customer.dart';
import '../../models/user/restaurant_owner.dart';
import '../../models/user/delivery_person.dart';

import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';

/// Simple, elegant splash screen with a logo animation and loading bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controller drives both the logo scale and the loading bar value.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // When the animation finishes, navigate to the next screen.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToHome();
      }
    });
  }

  Future<void> _goToHome() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final domainUser = await domain_user.User.getCurrentDomainUser();
    if (!mounted) return;
    late Widget destination;
    if (domainUser is Customer) {
      destination = const CustomerHomeScreen();
    } else if (domainUser is RestaurantOwner) {
      destination = const OwnerRestaurantSelectorScreen();
    } else if (domainUser is DeliveryPerson) {
      destination = const RiderDashboardScreen();
    } else {
      destination = const CustomerHomeScreen();
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryOrange, AppColors.peach],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo in a soft card-like circle.
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final scale = 0.85 + (_scaleAnimation.value * 0.35);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      size: 64,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Food Delivery',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delicious food, delivered fast',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Loading bar
                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: _controller.value,
                          backgroundColor: AppColors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                          minHeight: 6,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Getting things ready for you...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withOpacity(0.9),
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
