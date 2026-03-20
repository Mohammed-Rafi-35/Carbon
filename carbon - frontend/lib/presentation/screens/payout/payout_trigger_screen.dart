import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/payout_provider.dart';
import '../../../core/providers/sensor_provider.dart';
import '../../../core/routing/app_router.dart';

class PayoutTriggerScreen extends ConsumerStatefulWidget {
  const PayoutTriggerScreen({super.key});

  @override
  ConsumerState<PayoutTriggerScreen> createState() => _PayoutTriggerScreenState();
}

class _PayoutTriggerScreenState extends ConsumerState<PayoutTriggerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCollectingSensors = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleClaimProtection() async {
    final worker = ref.read(currentWorkerProvider);
    final order = ref.read(currentOrderProvider);

    if (worker == null || order == null) {
      _showError('Worker or order not found');
      return;
    }

    if (!order.meetsWeatherThreshold) {
      _showError('Weather conditions do not meet threshold for payout');
      return;
    }

    // Step 1: Collect sensor data (with ethical consent dialog)
    setState(() => _isCollectingSensors = true);

    final sensorData = await ref.read(sensorDataProvider.notifier).collectSensorData(context);

    if (sensorData == null) {
      if (mounted) {
        final error = ref.read(sensorDataProvider).error;
        _showError(error ?? 'Failed to collect sensor data');
        setState(() => _isCollectingSensors = false);
      }
      return;
    }

    // Step 2: Trigger payout
    if (mounted) {
      setState(() {
        _isCollectingSensors = false;
        _isProcessing = true;
      });

      final payout = await ref.read(payoutProvider.notifier).triggerPayout(
            workerId: worker.id,
            orderId: order.id,
            sensorData: sensorData,
          );

      if (mounted) {
        setState(() => _isProcessing = false);

        if (payout != null) {
          if (payout.status == 'approved') {
            _showSuccessDialog(payout.amount);
          } else {
            _showError('Payout ${payout.status}: ${payout.reason}');
          }
        } else {
          final error = ref.read(payoutProvider).error;
          _showError(error ?? 'Failed to process payout');
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    _animationController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payout Approved!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'has been credited to your wallet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed(AppRouter.home);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final order = ref.watch(currentOrderProvider);
    final sensorState = ref.watch(sensorDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Protection'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: order == null
            ? _buildNoOrderView(context, colorScheme, theme)
            : _buildClaimView(context, colorScheme, theme, sensorState),
      ),
    );
  }

  Widget _buildNoOrderView(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Order',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You need an active order to claim protection.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimView(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    SensorDataState sensorState,
  ) {
    final order = ref.watch(currentOrderProvider)!;
    final canClaim = order.meetsWeatherThreshold;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: canClaim
                ? colorScheme.tertiaryContainer
                : colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    canClaim ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: canClaim
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    canClaim ? 'Eligible for Protection' : 'Not Eligible',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: canClaim
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canClaim
                        ? 'Weather conditions meet the threshold'
                        : 'Weather conditions do not meet threshold',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: canClaim
                          ? colorScheme.onTertiaryContainer.withValues(alpha: 0.8)
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Process Steps
          _buildProcessStep(
            context,
            number: '1',
            title: 'Sensor Collection',
            description: 'GPS and accelerometer data will be collected',
            icon: Icons.sensors,
            isActive: _isCollectingSensors,
          ),
          const SizedBox(height: 16),
          _buildProcessStep(
            context,
            number: '2',
            title: 'Verification',
            description: 'Data will be verified for authenticity',
            icon: Icons.verified_user,
            isActive: _isProcessing,
          ),
          const SizedBox(height: 16),
          _buildProcessStep(
            context,
            number: '3',
            title: 'Payout',
            description: 'Amount will be credited to your wallet',
            icon: Icons.account_balance_wallet,
            isActive: false,
          ),
          const SizedBox(height: 32),

          // Claim Button
          ElevatedButton.icon(
            onPressed: (_isCollectingSensors || _isProcessing || !canClaim)
                ? null
                : _handleClaimProtection,
            icon: _isCollectingSensors || _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shield),
            label: Text(
              _isCollectingSensors
                  ? 'Collecting Sensor Data...'
                  : _isProcessing
                      ? 'Processing...'
                      : 'Claim Protection',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: canClaim ? colorScheme.tertiary : null,
              foregroundColor: canClaim ? colorScheme.onTertiary : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (!canClaim) ...[
            const SizedBox(height: 16),
            Text(
              'Weather conditions must meet the threshold to claim protection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isActive
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        number,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
