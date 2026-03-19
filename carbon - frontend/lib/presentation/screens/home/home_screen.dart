import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/payout_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final worker = ref.read(currentWorkerProvider);
    if (worker != null) {
      await ref.read(authProvider.notifier).refreshWorker();
      await ref.read(payoutProvider.notifier).loadPayoutHistory(worker.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final worker = ref.watch(currentWorkerProvider);
    final currentOrder = ref.watch(currentOrderProvider);
    final payoutState = ref.watch(payoutProvider);
    
    if (worker == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Worker not found',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushReplacementNamed(AppRouter.login);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'CARBON',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: colorScheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.profile);
                },
                tooltip: 'Profile',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    worker.phone,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Badge
                  StatusBadge(isActive: currentOrder != null),
                  const SizedBox(height: 24),
                  
                  // Wallet Balance
                  MetricCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Wallet Balance',
                    value: '₹${worker.walletBalance.toStringAsFixed(2)}',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Weekly Rides
                  MetricCard(
                    icon: Icons.two_wheeler,
                    label: 'Weekly Rides',
                    value: worker.weeklyRidesCompleted.toString(),
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  
                  // Total Payouts
                  MetricCard(
                    icon: Icons.payments,
                    label: 'Total Payouts',
                    value: payoutState.history.isEmpty
                        ? '₹0.00'
                        : '₹${payoutState.history.where((p) => p.status == 'approved').fold<double>(0, (sum, p) => sum + p.amount).toStringAsFixed(2)}',
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 32),
                  
                  // Quick Actions Header
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Order Button
                  _buildActionButton(
                    context,
                    icon: Icons.add_location_alt,
                    label: currentOrder == null ? 'Start New Order' : 'View Active Order',
                    color: colorScheme.primary,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.order);
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Claim Protection Button
                  if (currentOrder != null && currentOrder.meetsWeatherThreshold)
                    _buildActionButton(
                      context,
                      icon: Icons.shield,
                      label: 'Claim Protection',
                      color: colorScheme.tertiary,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.payoutTrigger);
                      },
                    ),
                  if (currentOrder != null && currentOrder.meetsWeatherThreshold)
                    const SizedBox(height: 12),
                  
                  // Transaction History Button
                  _buildActionButton(
                    context,
                    icon: Icons.history,
                    label: 'Transaction History',
                    color: colorScheme.secondary,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRouter.history);
                    },
                  ),
                  
                  // Recent Activity
                  if (payoutState.history.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...payoutState.history.take(3).map((payout) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(payout.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(payout.status),
                                color: _getStatusColor(payout.status),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payout.reason,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    payout.status.toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _getStatusColor(payout.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${payout.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: payout.status == 'approved'
                                    ? Colors.green
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        
        // Celebration Overlay
        if (_showCelebration)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 100,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '🎉 Payout Successful! 🎉',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
