import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/menu_types.dart';
import '../../../models/restaurant/restaurant.dart';
import '../../../models/restaurant/menu_item.dart';
import '../../../models/user/restaurant_owner.dart';
import '../../../models/user/user.dart' as domain_user;

final _currentOwnerProvider = FutureProvider<RestaurantOwner?>((ref) async {
  final u = await domain_user.User.getCurrentDomainUser();
  if (u is RestaurantOwner) return u;
  return null;
});

class OwnerMenuScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const OwnerMenuScreen({super.key, required this.restaurant});

  @override
  ConsumerState<OwnerMenuScreen> createState() => _OwnerMenuScreenState();
}

class _OwnerMenuScreenState extends ConsumerState<OwnerMenuScreen> {
  List<MenuItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final items = await widget.restaurant.getMenu();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu • ${widget.restaurant.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
        actions: [
          if (widget.restaurant.isApproved)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _openAddItemDialog(
                context,
                ref,
                AsyncValue.data(widget.restaurant),
              ),
              tooltip: 'Add Item',
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.lock_clock, color: Colors.grey),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenu,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: _items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No menu items yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildList(context, ref),
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref) {
    final uncategorized = <MenuItem>[];
    final categorized = <String, List<MenuItem>>{};
    final categoryIds = menu_categories.map((c) => c.id).toSet();
    for (final item in _items) {
      if (categoryIds.contains(item.categoryId)) {
        (categorized[item.categoryId] ??= []).add(item);
      } else {
        uncategorized.add(item);
      }
    }
    return ListView(
      children: [
        ...menu_categories.map((cat) {
          final catItems = categorized[cat.id] ?? const <MenuItem>[];
          if (catItems.isEmpty) return const SizedBox.shrink();
          return _categorySection(context, ref, cat.name, catItems);
        }),
        if (uncategorized.isNotEmpty)
          _categorySection(context, ref, 'Uncategorized', uncategorized),
      ],
    );
  }

  Widget _categorySection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<MenuItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = items[i];
                return ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.grey),
                  title: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    m.description.isEmpty
                        ? 'Category: ${m.categoryId}'
                        : m.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${m.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _availabilityChip(m.available),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openEditItemDialog(context, ref, m),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDelete(context, ref, m),
                      ),
                    ],
                  ),
                  onTap: () => _openEditItemDialog(context, ref, m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityChip(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(
          color: available ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openAddItemDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Restaurant?> restaurantAsync,
  ) async {
    final restaurant = restaurantAsync.asData?.value;
    if (restaurant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No restaurant found')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedCatId = menu_categories.isNotEmpty
        ? menu_categories.first.id
        : null;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.add, color: AppColors.primaryOrange),
              SizedBox(width: 8),
              Text(
                'Add New Menu Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: [
                    for (final c in menu_categories)
                      DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => selectedCatId = v),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final owner = await ref.read(_currentOwnerProvider.future);
                if (owner == null) return;
                final item = MenuItem(
                  id: '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  categoryId: selectedCatId ?? '',
                  available: true,
                );
                await owner.addMenuItem(item);
                Navigator.pop(context);
                await _loadMenu();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final categoryCtrl = TextEditingController(text: item.categoryId);
    bool available = item.available;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primaryOrange),
              SizedBox(width: 8),
              Text(
                'Edit Menu Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category ID',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: available,
                      onChanged: (val) => setState(() => available = val),
                      activeColor: AppColors.primaryOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final owner = await ref.read(_currentOwnerProvider.future);
                if (owner == null) return;
                await owner.updateMenuItem(
                  item.id,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  categoryId: categoryCtrl.text.trim(),
                  available: available,
                );
                Navigator.pop(context);
                await _loadMenu();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Confirm Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final owner = await ref.read(_currentOwnerProvider.future);
              if (owner == null) return;
              await owner.deleteMenuItem(item.id);
              Navigator.pop(context);
              await _loadMenu();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
