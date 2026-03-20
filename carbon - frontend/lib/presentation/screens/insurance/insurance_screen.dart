import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/insurance_provider.dart';
import '../../../data/models/insurance_summary.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final worker = ref.read(currentWorkerProvider);
    if (worker != null) {
      await ref.read(insuranceProvider.notifier).loadSummary(worker.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(insuranceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Plan'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? _buildError(context, cs, theme, state.error!)
                : state.summary == null
                    ? _buildEmpty(context, cs, theme)
                    : _buildDashboard(context, cs, theme, state.summary!),
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(error,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80,
              color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No insurance data',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ColorScheme cs, ThemeData theme,
      InsuranceSummary s) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTierCard(context, cs, theme, s),
        const SizedBox(height: 16),
        _buildFinancialsRow(context, cs, theme, s),
        const SizedBox(height: 16),
        _buildPolicyCard(context, cs, theme, s),
        const SizedBox(height: 16),
        if (s.frontLoadPeriod.isActive) ...[
          _buildFrontLoadBanner(context, cs, theme, s.frontLoadPeriod),
          const SizedBox(height: 16),
        ],
        _buildCoverageCard(context, cs, theme, s.coverageSummary),
        const SizedBox(height: 16),
        _buildRidesProgressCard(context, cs, theme, s),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Tier Card ─────────────────────────────────────────────────────────────

  Widget _buildTierCard(BuildContext context, ColorScheme cs, ThemeData theme,
      InsuranceSummary s) {
    final tier = s.tier;
    final tierColor = _tierColor(tier.tierName, cs);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              tierColor.withValues(alpha: 0.15),
              tierColor.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium, color: tierColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      Text(tier.ridesRequirement,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tier.activeRatePercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRateChip(context, 'Standard',
                    '${tier.standardRatePercent.toStringAsFixed(0)}%',
                    !tier.isFrontLoadPeriod, cs),
                const SizedBox(width: 8),
                _buildRateChip(context, 'Front-Load',
                    '${tier.frontLoadRatePercent.toStringAsFixed(0)}%',
                    tier.isFrontLoadPeriod, cs),
                const Spacer(),
                Text(
                  tier.isFrontLoadPeriod ? '🔥 Corpus Build' : '✅ Standard',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tier.isFrontLoadPeriod ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateChip(BuildContext context, String label, String value,
      bool isActive, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: cs.primary, width: 1.5) : null,
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? cs.onPrimaryContainer
                      : cs.onSurface.withValues(alpha: 0.5))),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? cs.onPrimaryContainer
                      : cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  // ── Financials Row ────────────────────────────────────────────────────────

  Widget _buildFinancialsRow(BuildContext context, ColorScheme cs,
      ThemeData theme, InsuranceSummary s) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(context, cs, theme,
              icon: Icons.currency_rupee,
              label: 'Weekly Premium',
              value: '₹${s.weeklyPremiumAmount.toStringAsFixed(2)}',
              subtitle: '${s.tier.activeRatePercent.toStringAsFixed(0)}% of income',
              color: cs.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(context, cs, theme,
              icon: Icons.shield,
              label: 'Payout Potential',
              value: '₹${s.payoutPotential.toStringAsFixed(2)}',
              subtitle: '20% of weekly income',
              color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, ColorScheme cs, ThemeData theme,
      {required IconData icon,
      required String label,
      required String value,
      required String subtitle,
      required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Policy Card ───────────────────────────────────────────────────────────

  Widget _buildPolicyCard(BuildContext context, ColorScheme cs, ThemeData theme,
      InsuranceSummary s) {
    final policy = s.policy;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user,
                    color: policy.isActive ? Colors.green : cs.error),
                const SizedBox(width: 12),
                Text('Policy Status',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: policy.isActive
                        ? Colors.green.withValues(alpha: 0.15)
                        : cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    policy.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: policy.isActive ? Colors.green : cs.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (policy.validUntil != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Valid Until',
                  dateFormat.format(policy.validUntil!)),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Premium Rate',
                '${policy.premiumRatePercent.toStringAsFixed(1)}% of weekly income'),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Projected Income',
                '₹${s.projectedWeeklyIncome.toStringAsFixed(2)}/week'),
          ],
        ),
      ),
    );
  }

  // ── Front-Load Banner ─────────────────────────────────────────────────────

  Widget _buildFrontLoadBanner(BuildContext context, ColorScheme cs,
      ThemeData theme, FrontLoadInfo fl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text('Corpus Build Period',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${fl.daysRemaining} days left',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(fl.purpose,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(
            'Temporarily higher premiums build the ₹55.5 Crore Disaster Ready fund.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ── Coverage Card ─────────────────────────────────────────────────────────

  Widget _buildCoverageCard(BuildContext context, ColorScheme cs,
      ThemeData theme, CoverageSummary cov) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.policy, color: cs.primary),
                const SizedBox(width: 12),
                Text('Coverage Details',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCoverageRow(context, Icons.check_circle, Colors.green,
                'Covers', cov.covers),
            const SizedBox(height: 10),
            _buildCoverageRow(context, Icons.cancel, cs.error,
                'Excludes', cov.excludes),
            const SizedBox(height: 10),
            _buildCoverageRow(context, Icons.thunderstorm, Colors.blue,
                'Triggers', cov.trigger),
            const SizedBox(height: 10),
            _buildCoverageRow(context, Icons.calculate, cs.secondary,
                'Payout Formula', cov.payoutFormula),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageRow(BuildContext context, IconData icon, Color color,
      String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Rides Progress Card ───────────────────────────────────────────────────

  Widget _buildRidesProgressCard(BuildContext context, ColorScheme cs,
      ThemeData theme, InsuranceSummary s) {
    final rides = s.weeklyRidesCompleted;
    final nextTierRides = rides < 70 ? 70 : (rides < 100 ? 100 : 100);
    final progress = rides >= 100 ? 1.0 : rides / nextTierRides.toDouble();
    final tierColor = _tierColor(s.tier.tierName, cs);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.two_wheeler, color: cs.secondary),
                const SizedBox(width: 12),
                Text('Weekly Rides',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$rides rides',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: tierColor)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: theme.textTheme.bodySmall),
                if (rides < 70)
                  Text('70 → Tier 2',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))
                else if (rides < 100)
                  Text('100 → Tier 1',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)))
                else
                  Text('Max Tier ✓',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                Text('${nextTierRides >= 100 ? "100+" : nextTierRides}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rides >= 100
                  ? 'You are at the highest tier — lowest premium rate!'
                  : 'Complete ${nextTierRides - rides} more rides to reach a better tier.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: cs.onSurface)),
      ],
    );
  }

  Color _tierColor(String tierName, ColorScheme cs) {
    switch (tierName) {
      case 'TIER_1': return Colors.amber.shade700;
      case 'TIER_2': return cs.secondary;
      default:       return cs.primary;
    }
  }
}
