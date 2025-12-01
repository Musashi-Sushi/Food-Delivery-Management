import 'package:flutter/material.dart';
import 'package:food/rider/screens/shell_screen.dart';
import 'package:food/rider/theme/app_colors.dart';

class DailyDeliApp extends StatelessWidget {
  const DailyDeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Deli — Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.lightPeach,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.darkText,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.darkText,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: AppColors.darkText,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.darkText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.darkText,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      home: const ShellScreen(),
    );
  }
}
