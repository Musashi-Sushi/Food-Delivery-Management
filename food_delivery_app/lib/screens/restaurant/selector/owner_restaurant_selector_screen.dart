import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/restaurant/restaurant.dart';
import '../../../models/restaurant/category_registry.dart';
import '../../../models/user/restaurant_owner.dart';
import '../../../models/user/user.dart' as domain_user;
import '../dashboard/restaurant_dashboard_screen.dart';

final _ownerProvider = FutureProvider<RestaurantOwner?>((ref) async {
  final u = await domain_user.User.getCurrentDomainUser();
  if (u is RestaurantOwner) return u;
  return null;
});

final _ownerRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  final owner = await ref.watch(_ownerProvider.future);
  if (owner == null) return [];
  return owner.getMyRestaurants();
});

class OwnerRestaurantSelectorScreen extends ConsumerWidget {
  const OwnerRestaurantSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(_ownerProvider);
    final restaurantsAsync = ref.watch(_ownerRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Restaurants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () =>
                _openCreateRestaurantDialog(context, ref, ownerAsync),
            tooltip: 'Add Restaurant',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_ownerRestaurantsProvider);
        },
        child: restaurantsAsync.when(
          data: (list) {
            final ownerId = ownerAsync.asData?.value?.id;
            final filtered = ownerId == null
                ? <Restaurant>[]
                : list.where((r) => r.ownerId == ownerId).toList();
            if (filtered.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No restaurants yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to create one',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = filtered[i];
                final approved = r.isApproved;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: r.imageUrl.isNotEmpty
                          ? NetworkImage(r.imageUrl)
                          : null,
                      child: r.imageUrl.isEmpty
                          ? const Icon(
                              Icons.store,
                              color: AppColors.primaryOrange,
                            )
                          : null,
                    ),
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      approved ? 'Approved' : 'Pending Approval',
                      style: TextStyle(
                        color: approved ? Colors.green : Colors.orange,
                      ),
                    ),
                    trailing: approved
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProviderScope(
                                    overrides: [
                                      injectedRestaurantProvider
                                          .overrideWithValue(r),
                                    ],
                                    child: const RestaurantDashboardScreen(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Open'),
                          )
                        : Chip(
                            label: const Text('Pending'),
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.orange),
                          ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Failed to load restaurants')),
        ),
      ),
    );
  }

  Future<void> _openCreateRestaurantDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<RestaurantOwner?> ownerAsync,
  ) async {
    final owner = ownerAsync.asData?.value;
    if (owner == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No owner found')));
      return;
    }
    final nameCtrl = TextEditingController();
    final cuisineCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final deliveryTimeCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final allCategories = CategoryRegistry.all;
    final selected = <String>{};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.add_business, color: AppColors.primaryOrange),
                SizedBox(width: 8),
                Text(
                  'Create Restaurant',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cuisineCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine',
                        prefixIcon: Icon(Icons.restaurant_menu),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: deliveryTimeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Time (min)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.category, color: AppColors.primaryOrange),
                        SizedBox(width: 8),
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in allCategories)
                              FilterChip(
                                label: Text(c.name),
                                selected: selected.contains(c.id),
                                onSelected: (sel) {
                                  setState(() {
                                    if (sel) {
                                      selected.add(c.id);
                                    } else {
                                      selected.remove(c.id);
                                    }
                                  });
                                },
                                selectedColor: AppColors.primaryOrange
                                    .withOpacity(0.2),
                                checkmarkColor: AppColors.primaryOrange,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final cuisine = cuisineCtrl.text.trim();
                  final image = imageCtrl.text.trim();
                  final delivery =
                      int.tryParse(deliveryTimeCtrl.text.trim()) ?? 30;
                  final lat = double.tryParse(latCtrl.text.trim()) ?? 0.0;
                  final lng = double.tryParse(lngCtrl.text.trim()) ?? 0.0;
                  await owner.createRestaurant(
                    name: name,
                    cuisine: cuisine,
                    deliveryTimeMinutes: delivery,
                    imageUrl: image,
                    latitude: lat,
                    longitude: lng,
                    categoryIds: selected.toList(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Restaurant submitted for approval'),
                      ),
                    );
                  }
                  ref.invalidate(_ownerRestaurantsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
