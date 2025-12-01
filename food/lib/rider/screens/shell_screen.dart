import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:food/rider/pages/completed_page.dart';
import 'package:food/rider/pages/dashboard_page.dart';
import 'package:food/rider/pages/live_nav_page.dart';
import 'package:food/rider/pages/pickup_page.dart';
import 'package:food/rider/pages/profile_page.dart';
import 'package:food/rider/data/dummy_data.dart';
import 'package:food/rider/theme/app_colors.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int selectedIndex = 0;
  int? hoveredIndex;

  Timer? _simTimer;
  bool _simulating = false;
  final Random _rng = Random();

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  void startSimulation() {
    if (_simulating) return;
    _simulating = true;
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        final dLat = (_rng.nextDouble() - 0.5) * 0.0008;
        final dLng = (_rng.nextDouble() - 0.5) * 0.0008;
        currentRider.currentLat = (currentRider.currentLat ?? 40.7128) + dLat;
        currentRider.currentLng = (currentRider.currentLng ?? -74.0060) + dLng;
        for (var i = 0; i < assignedDeliveries.length; i++) {
          assignedDeliveries[i].currentLat += dLat * (0.6 + i * 0.2);
          assignedDeliveries[i].currentLng += dLng * (0.6 + i * 0.2);
        }
      });
    });
  }

  void stopSimulation() {
    _simTimer?.cancel();
    _simTimer = null;
    _simulating = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Scaffold(
          body: Column(
            children: [
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryOrange,
                      child: const Icon(Icons.fastfood, color: AppColors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Daily Deli — Rider',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText),
                    ),
                    const Spacer(),
                    ..._buildTopNavItems(isNarrow),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: AppColors.lightPeach,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 28,
                    vertical: 18,
                  ),
                  child: _buildContent(selectedIndex, isNarrow),
                ),
              ),
            ],
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  Widget _buildContent(int idx, bool isNarrow) {
    switch (idx) {
      case 0:
        return DashboardPage(isNarrow: isNarrow);
      case 1:
        return const PickupPage();
      case 2:
        return LiveNavPage(
          simulating: _simulating,
          onToggleSim: () {
            setState(() {
              if (_simulating) {
                stopSimulation();
              } else {
                startSimulation();
              }
            });
          },
        );
      case 3:
        return const CompletedPage();
      case 4:
        return const ProfilePage();
      default:
        return DashboardPage(isNarrow: isNarrow);
    }
  }

  List<Widget> _buildTopNavItems(bool isNarrow) {
    final items = const [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.store_outlined, 'label': 'Pickup'},
      {'icon': Icons.navigation_outlined, 'label': 'Live Nav'},
      {'icon': Icons.check_circle_outline, 'label': 'Completed'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];
    return List.generate(items.length, (i) {
      final active = selectedIndex == i;
      final hover = hoveredIndex == i;
      final scale = active || hover ? 1.12 : 1.0;
      final bg = active
          ? AppColors.primaryOrange
          : hover
              ? AppColors.peach.withOpacity(0.35)
              : Colors.transparent;
      final fg = active ? AppColors.white : AppColors.darkText;
      return MouseRegion(
        onEnter: (_) => setState(() => hoveredIndex = i),
        onExit: (_) => setState(() => hoveredIndex = null),
        child: GestureDetector(
          onTap: () => setState(() => selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Row(
                children: [
                  Icon(items[i]['icon'] as IconData, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(color: fg, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
