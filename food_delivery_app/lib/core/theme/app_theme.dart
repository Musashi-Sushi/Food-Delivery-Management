import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightPeachBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        brightness: Brightness.light,
        primary: AppColors.primaryOrange,
        secondary: AppColors.peach,
        surface: AppColors.lightPeachBackground,
        onPrimary: AppColors.white,
        onSurface: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPeachBackground,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.darkText,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkText),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.darkText),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        linearTrackColor: AppColors.peach,
      ),
    );
  }
}
