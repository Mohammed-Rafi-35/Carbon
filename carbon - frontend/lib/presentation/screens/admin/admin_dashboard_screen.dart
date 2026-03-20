import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/routing/app_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Pulse'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(adminProvider.notifier).logout();
              Navigator.of(context).pushReplacementNamed(AppRouter.adminLogin);
            },
          ),
        ],
      ),
      body: state.isLoading && state.dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : state.dashboard == null
              ? _buildError(context, cs, state.error)
              : _buildDashboard(context, theme, cs, state.dashboard!),
      bottomNavigationBar: const _AdminNavBar(currentIndex: 0),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(error ?? 'Failed to load dashboard'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(adminProvider.notifier).loadDashboard(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ThemeData theme,
      ColorScheme cs, Map<String, dynamic> data) {
    final workers = data['workers'] as Map<String, dynamic>;
    final financials = data['financials'] as Map<String, dynamic>;
    final disruptions = data['disruptions'] as Map<String, dynamic>;
    final last24h = data['last_24h'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Workers'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Total',
                      value: '${workers['total']}',
                      icon: Icons.people,
                      color: cs.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Active',
                      value: '${workers['active']}',
                      icon: Icons.check_circle,
                      color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Inactive',
                      value: '${workers['inactive']}',
                      icon: Icons.block,
                      color: cs.error)),
            ]),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Financials'),
            const SizedBox(height: 8),
            _FinancialCard(financials: financials),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Disruptions'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Total Orders',
                      value: '${disruptions['total_orders']}',
                      icon: Icons.receipt_long,
                      color: cs.secondary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Threshold Met',
                      value: '${disruptions['threshold_met']}',
                      icon: Icons.warning_amber,
                      color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Rate',
                      value:
                          '${((disruptions['disruption_rate'] as num) * 100).toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      color: Colors.deepOrange)),
            ]),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Last 24 Hours'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Payouts',
                      value: '${last24h['payouts']}',
                      icon: Icons.payments,
                      color: cs.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Orders',
                      value: '${last24h['orders']}',
                      icon: Icons.delivery_dining,
                      color: cs.secondary)),
            ]),
            const SizedBox(height: 20),

            _sectionLabel(theme, 'Quick Actions'),
            const SizedBox(height: 8),
            const _QuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) => Text(
        label,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
}

class _FinancialCard extends StatelessWidget {
  final Map<String, dynamic> financials;
  const _FinancialCard({required this.financials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final premiums =
        (financials['total_premiums_collected'] as num).toDouble();
    final payouts = (financials['total_payouts_disbursed'] as num).toDouble();
    final corpus = (financials['net_corpus'] as num).toDouble();
    final lossRatio = (financials['loss_ratio'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _FinRow(
                    label: 'Premiums Collected',
                    value: '₹${premiums.toStringAsFixed(2)}',
                    color: Colors.green)),
            const SizedBox(width: 16),
            Expanded(
                child: _FinRow(
                    label: 'Payouts Disbursed',
                    value: '₹${payouts.toStringAsFixed(2)}',
                    color: cs.error)),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(
                child: _FinRow(
                    label: 'Net Corpus',
                    value: '₹${corpus.toStringAsFixed(2)}',
                    color: corpus >= 0 ? Colors.green : cs.error)),
            const SizedBox(width: 16),
            Expanded(
                child: _FinRow(
              label: 'Loss Ratio',
              value: '${(lossRatio * 100).toStringAsFixed(1)}%',
              color: lossRatio < 0.7
                  ? Colors.green
                  : lossRatio < 0.9
                      ? Colors.orange
                      : cs.error,
            )),
          ]),
          const Divider(height: 24),
          Row(children: [
            Expanded(
                child: _FinRow(
                    label: 'Payout Count',
                    value: '${financials['payout_count']}',
                    color: theme.colorScheme.onSurface)),
            const SizedBox(width: 16),
            Expanded(
                child: _FinRow(
                    label: 'Premium Count',
                    value: '${financials['premium_count']}',
                    color: theme.colorScheme.onSurface)),
          ]),
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      Text(value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionChip(
            label: 'Fraud Queue',
            icon: Icons.security,
            color: cs.error,
            route: AppRouter.adminFraudQueue),
        _ActionChip(
            label: 'Analytics',
            icon: Icons.bar_chart,
            color: cs.primary,
            route: AppRouter.adminAnalytics),
        _ActionChip(
            label: 'Workers',
            icon: Icons.people,
            color: cs.secondary,
            route: AppRouter.adminWorkers),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: () => Navigator.of(context).pushNamed(route),
    );
  }
}

class _AdminNavBar extends ConsumerWidget {
  final int currentIndex;
  const _AdminNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        final routes = [
          AppRouter.adminDashboard,
          AppRouter.adminFraudQueue,
          AppRouter.adminAnalytics,
          AppRouter.adminWorkers,
        ];
        if (i != currentIndex) {
          Navigator.of(context).pushReplacementNamed(routes[i]);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.security), label: 'Fraud'),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        NavigationDestination(icon: Icon(Icons.people), label: 'Workers'),
      ],
    );
  }
}
