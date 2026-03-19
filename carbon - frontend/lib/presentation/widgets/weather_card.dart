import 'package:flutter/material.dart';
import '../../data/models/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.weather,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.cloud,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weather Conditions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (weather.meetsThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ELIGIBLE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Weather Metrics
              _buildWeatherMetric(
                context,
                icon: Icons.water_drop,
                label: 'Rainfall',
                value: '${weather.rainMm.toStringAsFixed(1)} mm',
                threshold: 'Threshold: ${weather.rainThreshold} mm',
                meetsThreshold: weather.rainMm >= weather.rainThreshold,
              ),
              const SizedBox(height: 16),
              _buildWeatherMetric(
                context,
                icon: Icons.air,
                label: 'Wind Speed',
                value: '${weather.windKmh.toStringAsFixed(1)} km/h',
                threshold: 'Threshold: ${weather.windThreshold} km/h',
                meetsThreshold: weather.windKmh >= weather.windThreshold,
              ),
              const SizedBox(height: 16),
              _buildWeatherMetric(
                context,
                icon: Icons.thermostat,
                label: 'Temperature',
                value: '${weather.tempC.toStringAsFixed(1)}°C',
                threshold: 'Threshold: ${weather.tempThreshold}°C',
                meetsThreshold: weather.tempC >= weather.tempThreshold,
              ),

              // Threshold Reason
              if (weather.meetsThreshold && weather.thresholdReason != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          weather.thresholdReason!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String threshold,
    required bool meetsThreshold,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: meetsThreshold
                ? colorScheme.tertiaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: meetsThreshold
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurface,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                threshold,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        if (meetsThreshold)
          Icon(
            Icons.check_circle,
            color: colorScheme.tertiary,
            size: 24,
          ),
      ],
    );
  }
}
