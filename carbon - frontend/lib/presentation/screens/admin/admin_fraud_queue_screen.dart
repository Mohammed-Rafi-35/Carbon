import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/routing/app_router.dart';

class AdminFraudQueueScreen extends ConsumerStatefulWidget {
  const AdminFraudQueueScreen({super.key});

  @override
  ConsumerState<AdminFraudQueueScreen> createState() =>
      _AdminFraudQueueScreenState();
}

class _AdminFraudQueueScreenState
    extends ConsumerState<AdminFraudQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadFraudQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Quarantine Queue'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadFraudQueue(),
          ),
        ],
      ),
      body: state.isLoading && state.fraudQueue == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, theme, cs, state),
      bottomNavigationBar: _AdminNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ColorScheme cs,
      AdminState state) {
    if (state.fraudQueue == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(state.error ?? 'Failed to load fraud queue'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(adminProvider.notifier).loadFraudQueue(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final queue = (state.fraudQueue!['queue'] as List<dynamic>?) ?? [];
    final total = state.fraudQueue!['total_flagged'] ?? 0;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).loadFraudQueue(),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: cs.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total Flagged Claims',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onErrorContainer,
                        ),
                      ),
                      Text(
                        'Claims rejected by sensor fusion gate',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onErrorContainer.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text('No flagged claims',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'All claims are passing the fraud gate',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: queue.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = queue[i] as Map<String, dynamic>;
                      return _FraudCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FraudCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FraudCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ts = item['timestamp'] as String? ?? '';
    final date = ts.isNotEmpty ? ts.substring(0, 10) : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: cs.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['worker_name'] ?? 'Unknown Worker',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'QUARANTINED',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Phone', value: item['worker_phone'] ?? '-'),
          _InfoRow(label: 'Zone', value: item['worker_zone'] ?? '-'),
          _InfoRow(
              label: 'Amount',
              value: '₹${(item['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
          _InfoRow(label: 'Date', value: date),
          if (item['reason'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item['reason'].toString(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
          ),
          Text(value, style: theme.textTheme.bodySmall),
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
