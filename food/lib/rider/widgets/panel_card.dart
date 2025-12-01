import 'package:flutter/material.dart';
import 'package:food/rider/theme/app_colors.dart';

class PanelCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expandChild;
  const PanelCard({super.key, required this.title, required this.child, this.expandChild = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 10),
          if (expandChild)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: child,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
        ],
      ),
    );
  }
}
