import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/routing/app_router.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAnalytics(days: _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disruption Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(adminProvider.notifier)
                .loadAnalytics(days: _selectedDays),
          ),
        ],
      ),
      body: Column(
        children: [
          _DaySelector(
            selected: _selectedDays,
            onChanged: (d) {
              setState(() => _selectedDays = d);
              ref.read(adminProvider.notifier).loadAnalytics(days: d);
            },
          ),
          Expanded(
            child: state.isLoading && state.analytics == null
                ? const Center(child: CircularProgressIndicator())
                : state.analytics == null
                    ? _buildError(context, cs, state.error)
                    : _buildBody(context, theme, cs, state.analytics!),
          ),
        ],
      ),
      bottomNavigationBar: _AdminNavBar(currentIndex: 2),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(error ?? 'Failed to load analytics'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref
                .read(adminProvider.notifier)
                .loadAnalytics(days: _selectedDays),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme cs,
      Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>;
    final triggers =
        (data['trigger_breakdown'] as Map<String, dynamic>?) ?? {};
    final zones = (data['zone_breakdown'] as Map<String, dynamic>?) ?? {};
    final events =
        (data['disruption_events'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () => ref
          .read(adminProvider.notifier)
          .loadAnalytics(days: _selectedDays),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(children: [
              Expanded(
                  child: _StatCard(
                      label: 'Disruptions',
                      value: '${summary['total_disruptions']}',
                      icon: Icons.thunderstorm,
                      color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Payouts',
                      value: '${summary['total_payouts']}',
                      icon: Icons.payments,
                      color: cs.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      label: 'Amount',
                      value:
                          '₹${(summary['total_payout_amount'] as num).toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      color: Colors.green)),
            ]),
            const SizedBox(height: 20),

            // Trigger breakdown
            if (triggers.isNotEmpty) ...[
              Text('Trigger Breakdown',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _TriggerBreakdown(triggers: triggers),
              const SizedBox(height: 20),
            ],

            // Zone breakdown
            if (zones.isNotEmpty) ...[
              Text('Zone Breakdown',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...zones.entries.map((e) => _ZoneRow(
                    zone: e.key,
                    stats: e.value as Map<String, dynamic>,
                  )),
              const SizedBox(height: 20),
            ],

            // Recent events
            if (events.isNotEmpty) ...[
              Text('Recent Disruption Events',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...events.take(10).map((e) {
                final ev = e as Map<String, dynamic>;
                final ts = ev['timestamp'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev['zone'] ?? 'Unknown Zone',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(ev['reason'] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      Text(
                        ts.length >= 10 ? ts.substring(0, 10) : ts,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _DaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [7, 14, 30].map((d) {
          final isSelected = d == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${d}d'),
              selected: isSelected,
              onSelected: (_) => onChanged(d),
              selectedColor: cs.primaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
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

class _TriggerBreakdown extends StatelessWidget {
  final Map<String, dynamic> triggers;
  const _TriggerBreakdown({required this.triggers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total =
        triggers.values.fold<int>(0, (s, v) => s + (v as int));

    final colors = {
      'Heavy Rain': Colors.blue,
      'High Wind': Colors.teal,
      'Extreme Cold': Colors.indigo,
      'Extreme Heat': Colors.deepOrange,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: triggers.entries.map((e) {
          final pct = total > 0 ? (e.value as int) / total : 0.0;
          final color = colors[e.key] ?? cs.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: theme.textTheme.bodyMedium),
                    Text('${e.value}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String zone;
  final Map<String, dynamic> stats;
  const _ZoneRow({required this.zone, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(zone,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Text('${stats['disruptions'] ?? 0} disruptions',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orange)),
          const SizedBox(width: 12),
          Text('${stats['payouts'] ?? 0} payouts',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.primary)),
        ],
      ),
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
