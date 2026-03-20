import 'package:flutter/material.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/order/order_screen.dart';
import '../../presentation/screens/payout/payout_trigger_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/settings/network_settings_screen.dart';
import '../../presentation/screens/insurance/insurance_screen.dart';
import '../../presentation/screens/admin/admin_login_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_fraud_queue_screen.dart';
import '../../presentation/screens/admin/admin_analytics_screen.dart';
import '../../presentation/screens/admin/admin_workers_screen.dart';
import '../../presentation/screens/admin/admin_data_report_screen.dart';
import '../../presentation/screens/profile/data_transparency_screen.dart';

/// Centralized routing configuration for the Carbon app
class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String order = '/order';
  static const String payoutTrigger = '/payout-trigger';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String networkSettings = '/network-settings';
  static const String insurance = '/insurance';
  static const String adminLogin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminFraudQueue = '/admin/fraud-queue';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminWorkers = '/admin/workers';
  static const String adminDataReport = '/admin/data-report';
  static const String dataTransparency = '/data-transparency';

  /// Generate routes based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(
          const SplashScreen(),
          settings: settings,
        );
      
      case login:
        return _buildRoute(
          const LoginScreen(),
          settings: settings,
        );
      
      case register:
        return _buildRoute(
          const RegisterScreen(),
          settings: settings,
        );
      
      case home:
        return _buildRoute(
          const HomeScreen(),
          settings: settings,
        );
      
      case order:
        return _buildRoute(
          const OrderScreen(),
          settings: settings,
        );
      
      case payoutTrigger:
        return _buildRoute(
          const PayoutTriggerScreen(),
          settings: settings,
        );
      
      case history:
        return _buildRoute(
          const HistoryScreen(),
          settings: settings,
        );
      
      case profile:
        return _buildRoute(
          const ProfileScreen(),
          settings: settings,
        );
      
      case networkSettings:
        return _buildRoute(const NetworkSettingsScreen(), settings: settings);

      case insurance:
        return _buildRoute(const InsuranceScreen(), settings: settings);

      case adminLogin:
        return _buildRoute(const AdminLoginScreen(), settings: settings);

      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings: settings);

      case adminFraudQueue:
        return _buildRoute(const AdminFraudQueueScreen(), settings: settings);

      case adminAnalytics:
        return _buildRoute(const AdminAnalyticsScreen(), settings: settings);

      case adminWorkers:
        return _buildRoute(const AdminWorkersScreen(), settings: settings);

      case adminDataReport:
        final workerId = settings.arguments as String;
        return _buildRoute(
          AdminDataReportScreen(workerId: workerId),
          settings: settings,
        );

      case dataTransparency:
        return _buildRoute(const DataTransparencyScreen(), settings: settings);

      default:
        return _buildRoute(
          const NotFoundScreen(),
          settings: settings,
        );
    }
  }

  /// Build route with custom transition
  static MaterialPageRoute _buildRoute(
    Widget screen, {
    required RouteSettings settings,
  }) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('404 - Screen Not Found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
