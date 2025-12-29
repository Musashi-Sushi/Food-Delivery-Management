import 'package:food_delivery_app/models/restaurant/category.dart';

class CategoryRegistry {
  static final Map<String, Category> _categories = {
    // 🔥 Popular Fast Food
    'burgers': Category(id: 'burgers', name: 'Burgers'),
    'pizza': Category(id: 'pizza', name: 'Pizza'),
    'sandwiches': Category(id: 'sandwiches', name: 'Sandwiches'),
    'fried_chicken': Category(id: 'fried_chicken', name: 'Fried Chicken'),
    'bbq': Category(id: 'bbq', name: 'BBQ'),
    'fast_food': Category(id: 'fast_food', name: 'Fast Food'),

    // 🍣 Asian
    'sushi': Category(id: 'sushi', name: 'Sushi'),
    'japanese': Category(id: 'japanese', name: 'Japanese'),
    'chinese': Category(id: 'chinese', name: 'Chinese'),
    'thai': Category(id: 'thai', name: 'Thai'),
    'korean': Category(id: 'korean', name: 'Korean'),
    'ramen': Category(id: 'ramen', name: 'Ramen'),
    'seafood': Category(id: 'seafood', name: 'Seafood'),

    // 🍝 European
    'italian': Category(id: 'italian', name: 'Italian'),
    'pasta': Category(id: 'pasta', name: 'Pasta'),
    'steakhouse': Category(id: 'steakhouse', name: 'Steakhouse'),

    // 🌮 Latin / Mexican
    'mexican': Category(id: 'mexican', name: 'Mexican'),
    'tacos': Category(id: 'tacos', name: 'Tacos'),
    'burritos': Category(id: 'burritos', name: 'Burritos'),

    // 🍛 Middle Eastern & Desi
    'desi': Category(id: 'desi', name: 'Desi (Pak/Indian)'),
    'biryani': Category(id: 'biryani', name: 'Biryani'),
    'shawarma': Category(id: 'shawarma', name: 'Shawarma'),
    'arabic': Category(id: 'arabic', name: 'Arabic'),
    'kebabs': Category(id: 'kebabs', name: 'Kebabs'),

    // 🥗 Healthy / Lifestyle
    'healthy': Category(id: 'healthy', name: 'Healthy'),
    'salads': Category(id: 'salads', name: 'Salads'),
    'vegan': Category(id: 'vegan', name: 'Vegan'),
    'vegetarian': Category(id: 'vegetarian', name: 'Vegetarian'),

    // 🍰 Desserts & Bakery
    'desserts': Category(id: 'desserts', name: 'Desserts'),
    'ice_cream': Category(id: 'ice_cream', name: 'Ice Cream'),
    'cakes': Category(id: 'cakes', name: 'Cakes'),
    'donuts': Category(id: 'donuts', name: 'Donuts'),
    'bakers': Category(id: 'bakers', name: 'Bakery'),
    'coffee': Category(id: 'coffee', name: 'Coffee'),
    'drinks': Category(id: 'drinks', name: 'Drinks'),

    // 🌍 Others / General
    'breakfast': Category(id: 'breakfast', name: 'Breakfast'),
    'brunch': Category(id: 'brunch', name: 'Brunch'),
    'grill': Category(id: 'grill', name: 'Grill'),
    'noodles': Category(id: 'noodles', name: 'Noodles'),
    'wraps': Category(id: 'wraps', name: 'Wraps'),
  };

  static Category? getById(String id) {
    return _categories[id];
  }

  static List<Category> get all => _categories.values.toList();
}
