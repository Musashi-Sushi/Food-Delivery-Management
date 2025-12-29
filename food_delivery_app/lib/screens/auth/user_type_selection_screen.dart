import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Simple screen to choose what type of user is logging in.
class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget buildTypeButton(String label, IconData icon) {
      return SizedBox(
        width: 220,
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to specific dashboard based on type.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label selected (not wired yet)')),
            );
          },
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select user type')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Who are you?', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to use the app.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  buildTypeButton('Customer', Icons.person_outline),
                  buildTypeButton('Restaurant owner', Icons.storefront_outlined),
                  buildTypeButton('Rider', Icons.delivery_dining),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
