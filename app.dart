import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/daily_collection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/loan_detail_screen.dart';
import 'utils/constants.dart';

class DailyCollectionApp extends StatelessWidget {
  const DailyCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
      routes: {
        '/customers': (ctx) => const CustomerListScreen(),
        '/daily_collection': (ctx) => const DailyCollectionScreen(),
        '/settings': (ctx) => const SettingsScreen(),
        '/loan_detail': (ctx) => const LoanDetailRoute(),
      },
    );
  }
}

// Wrapper for named route to loan detail
class LoanDetailRoute extends StatelessWidget {
  const LoanDetailRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final loanId = ModalRoute.of(context)!.settings.arguments as int;
    return LoanDetailScreen(loanId: loanId);
  }
}
