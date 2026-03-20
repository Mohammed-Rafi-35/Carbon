import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/routing/app_router.dart';

class AdminWorkersScreen extends ConsumerStatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  ConsumerState<AdminWorkersScreen> createState() =>
      _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends ConsumerState<AdminWorkersScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadWorkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadWorkers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or zone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: cs.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: state.isLoading && state.workerList == null
                ? const Center(child: CircularProgressIndicator())
                : state.workerList == null
                    ? _buildError(context, cs, state.error)
                    : _buildList(context, theme, cs, state),
          ),
        ],
      ),
      bottomNavigationBar: _AdminNavBar(currentIndex: 3),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(error ?? 'Failed to load workers'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(adminProvider.notifier).loadWorkers(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ThemeData theme, ColorScheme cs,
      AdminState state) {
    final allWorkers =
        (state.workerList!['workers'] as List<dynamic>?) ?? [];
    final total = state.workerList!['total'] ?? 0;

    final filtered = _search.isEmpty
        ? allWorkers
        : allWorkers.where((w) {
            final worker = w as Map<String, dynamic>;
            return (worker['name'] as String? ?? '')
                    .toLowerCase()
                    .contains(_search) ||
                (worker['zone'] as String? ?? '')
                    .toLowerCase()
                    .contains(_search);
          }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).loadWorkers(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('$total total workers',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6))),
                if (_search.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('· ${filtered.length} shown',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.primary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final worker = filtered[i] as Map<String, dynamic>;
                return _WorkerCard(
                  worker: worker,
                  onDeactivate: () => _confirmAction(
                    context,
                    title: 'Deactivate Worker',
                    message:
                        'Deactivate ${worker['name']}? They will lose access to the platform.',
                    confirmLabel: 'Deactivate',
                    isDestructive: true,
                    onConfirm: () => ref
                        .read(adminProvider.notifier)
                        .deactivateWorker(worker['id'] as String),
                  ),
                  onReactivate: () => _confirmAction(
                    context,
                    title: 'Reactivate Worker',
                    message: 'Reactivate ${worker['name']}?',
                    confirmLabel: 'Reactivate',
                    isDestructive: false,
                    onConfirm: () => ref
                        .read(adminProvider.notifier)
                        .reactivateWorker(worker['id'] as String),
                  ),
                  onViewData: () => Navigator.of(context).pushNamed(
                    AppRouter.adminDataReport,
                    arguments: worker['id'] as String,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
    required Future<bool> Function() onConfirm,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await onConfirm();
      messenger.showSnackBar(SnackBar(
        content: Text(ok ? '$confirmLabel successful' : 'Action failed'),
        backgroundColor: ok ? Colors.green : cs.error,
      ));
    }
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  final VoidCallback onViewData;

  const _WorkerCard({
    required this.worker,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onViewData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = worker['is_active'] as bool? ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? null
            : Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isActive ? cs.primaryContainer : cs.errorContainer,
                child: Icon(
                  Icons.person,
                  color: isActive ? cs.onPrimaryContainer : cs.onErrorContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker['name'] ?? 'Unknown',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(worker['phone'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? Colors.green : cs.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Tag(icon: Icons.location_on, label: worker['zone'] ?? '-'),
              const SizedBox(width: 8),
              _Tag(
                  icon: Icons.two_wheeler,
                  label: (worker['vehicle_type'] as String? ?? '-')
                      .toUpperCase()),
              const SizedBox(width: 8),
              _Tag(
                  icon: Icons.account_balance_wallet,
                  label:
                      '₹${(worker['wallet_balance'] as num?)?.toStringAsFixed(0) ?? '0'}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewData,
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('Data Report'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isActive
                    ? OutlinedButton.icon(
                        onPressed: onDeactivate,
                        icon: Icon(Icons.block, size: 16, color: cs.error),
                        label: Text('Deactivate',
                            style: TextStyle(color: cs.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: cs.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onReactivate,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Reactivate'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7))),
      ],
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
