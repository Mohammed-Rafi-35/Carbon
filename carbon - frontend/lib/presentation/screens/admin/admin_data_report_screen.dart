import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/admin_provider.dart';

class AdminDataReportScreen extends ConsumerStatefulWidget {
  final String workerId;
  const AdminDataReportScreen({super.key, required this.workerId});

  @override
  ConsumerState<AdminDataReportScreen> createState() =>
      _AdminDataReportScreenState();
}

class _AdminDataReportScreenState
    extends ConsumerState<AdminDataReportScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final report = await ref
        .read(adminProvider.notifier)
        .getWorkerDataReport(widget.workerId);
    if (mounted) {
      setState(() {
        _report = report;
        _loading = false;
        _error = report == null ? 'Failed to load data report' : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Transparency Report'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context, cs)
              : _buildReport(context, theme, cs, _report!),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(_error!),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context, ThemeData theme, ColorScheme cs,
      Map<String, dynamic> data) {
    final worker = data['worker'] as Map<String, dynamic>;
    final policy = data['policy'] as Map<String, dynamic>;
    final sensorPolicy = data['sensor_data_policy'] as Map<String, dynamic>;
    final transactions =
        (data['transactions'] as List<dynamic>?) ?? [];
    final weatherSnaps =
        (data['weather_snapshots'] as List<dynamic>?) ?? [];
    final generatedAt = data['report_generated_at'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: cs.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DPDP Act 2023 Compliant',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer)),
                      Text(
                          'Generated: ${generatedAt.length >= 10 ? generatedAt.substring(0, 10) : generatedAt}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Worker profile
          _Section(
            title: 'Worker Profile',
            icon: Icons.person,
            child: Column(
              children: [
                _DataRow('Name', worker['name'] ?? '-'),
                _DataRow('Phone', worker['phone'] ?? '-'),
                _DataRow('Zone', worker['zone'] ?? '-'),
                _DataRow('Vehicle', (worker['vehicle_type'] as String? ?? '-').toUpperCase()),
                _DataRow('Wallet Balance', '₹${(worker['wallet_balance'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                _DataRow('Weekly Rides', '${worker['weekly_rides_completed'] ?? 0}'),
                _DataRow('Status', (worker['is_active'] as bool? ?? true) ? 'Active' : 'Inactive'),
                _DataRow('Joined', (worker['joined_at'] as String? ?? '').substring(0, 10 > (worker['joined_at'] as String? ?? '').length ? (worker['joined_at'] as String? ?? '').length : 10)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Policy
          _Section(
            title: 'Insurance Policy',
            icon: Icons.shield,
            child: Column(
              children: [
                _DataRow('Policy Active', (policy['is_active'] as bool? ?? false) ? 'Yes' : 'No'),
                if (policy['premium_rate_percent'] != null)
                  _DataRow('Premium Rate', '${policy['premium_rate_percent']}%'),
                if (policy['valid_until'] != null)
                  _DataRow('Valid Until', (policy['valid_until'] as String).substring(0, 10)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sensor data policy
          _Section(
            title: 'Sensor Data Policy',
            icon: Icons.sensors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletList(
                    label: 'Data Collected',
                    items: (sensorPolicy['collected'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        []),
                const SizedBox(height: 8),
                _BulletList(
                    label: 'Not Collected',
                    items: (sensorPolicy['not_collected'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    color: Colors.green),
                const SizedBox(height: 8),
                _DataRow('Retention', sensorPolicy['retention'] ?? '-'),
                _DataRow('Purpose', sensorPolicy['purpose'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transactions
          _Section(
            title: 'Transaction History (${transactions.length})',
            icon: Icons.receipt_long,
            child: transactions.isEmpty
                ? const Text('No transactions recorded')
                : Column(
                    children: transactions.take(20).map((t) {
                      final tx = t as Map<String, dynamic>;
                      final ts = tx['timestamp'] as String? ?? '';
                      final isPayout = tx['type'] == 'PAYOUT';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              isPayout
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: isPayout ? Colors.green : cs.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx['type'] ?? '',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(tx['reason'] ?? '',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.6)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '₹${(tx['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isPayout
                                            ? Colors.green
                                            : cs.error)),
                                Text(
                                    ts.length >= 10
                                        ? ts.substring(0, 10)
                                        : ts,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Weather snapshots
          _Section(
            title: 'Weather Snapshots (${weatherSnaps.length})',
            icon: Icons.cloud,
            child: weatherSnaps.isEmpty
                ? const Text('No weather snapshots recorded')
                : Column(
                    children: weatherSnaps.take(10).map((w) {
                      final snap = w as Map<String, dynamic>;
                      final ts = snap['timestamp'] as String? ?? '';
                      final met = snap['meets_threshold'] as bool? ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              met ? Icons.warning_amber : Icons.check_circle,
                              size: 16,
                              color: met ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                snap['threshold_reason'] ?? 'No trigger',
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ts.length >= 10 ? ts.substring(0, 10) : ts,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color? color;
  const _BulletList(
      {required this.label, required this.items, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(
                          color: color ?? cs.onSurface, fontSize: 12)),
                  Expanded(
                    child: Text(item,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: color)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
