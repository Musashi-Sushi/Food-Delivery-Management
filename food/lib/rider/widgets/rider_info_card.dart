import 'package:flutter/material.dart';
import 'package:food/rider/models/models.dart';
import 'package:food/rider/theme/app_colors.dart';

class RiderInfoCard extends StatelessWidget {
  final DeliveryPerson rider;
  const RiderInfoCard({super.key, required this.rider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primaryOrange,
          child: const Icon(Icons.person, color: AppColors.white, size: 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rider.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
              const SizedBox(height: 6),
              Text(rider.emailAddress, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(8)),
                    child: Text("Status: ${rider.status.name}", style: const TextStyle(color: AppColors.darkText)),
                  ),
                  const SizedBox(width: 10),
                  Text("Phone: ${rider.phoneNumber}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
