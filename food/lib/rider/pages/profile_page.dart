import 'package:flutter/material.dart';
import 'package:food/rider/data/dummy_data.dart';
import 'package:food/rider/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 860,
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.peach],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(radius: 56, backgroundColor: AppColors.white.withOpacity(0.18), child: const Icon(Icons.person, color: AppColors.white, size: 40)),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentRider.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentRider.emailAddress,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white.withOpacity(0.95)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('Status: ${currentRider.status.name}', style: const TextStyle(color: AppColors.white)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.white),
                          const SizedBox(width: 6),
                          Text('Completed: ${completedDeliveries.length}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.navigation, color: AppColors.white),
                          SizedBox(width: 6),
                          Text('On duty', style: TextStyle(color: AppColors.white)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoChip(icon: Icons.phone, label: currentRider.phoneNumber),
                _InfoChip(icon: Icons.email, label: currentRider.emailAddress),
                _InfoChip(icon: Icons.badge, label: 'Rider ID: ${currentRider.id}'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                  label: const Text('Edit Profile'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.darkText),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
