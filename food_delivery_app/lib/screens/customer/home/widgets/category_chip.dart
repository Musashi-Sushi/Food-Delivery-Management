import 'package:flutter/material.dart';

import '../../../../models/restaurant/category.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final Category category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(category.name),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryOrange,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.darkText,
      ),
      backgroundColor: AppColors.peach,
    );
  }
}