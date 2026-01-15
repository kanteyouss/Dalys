import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Trend { up, down, stable, unknown }

class HealthIndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String normalRange;
  final VoidCallback? onTap;
  final Trend trend;

  const HealthIndicatorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.normalRange,
    this.onTap,
    this.trend = Trend.unknown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                        ),
                      ),
                      if (trend != Trend.unknown) _buildTrendIcon(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Normal: $normalRange',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIcon() {
    IconData iconData;
    Color iconColor;

    switch (trend) {
      case Trend.up:
        iconData = Icons.arrow_upward;
        iconColor = Colors.red;
        break;
      case Trend.down:
        iconData = Icons.arrow_downward;
        iconColor = Colors.green;
        break;
      case Trend.stable:
        iconData = Icons.remove;
        iconColor = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    if (title.contains('SpO₂') || title.contains('PEF')) {
      if (trend == Trend.up) iconColor = Colors.green;
      if (trend == Trend.down) iconColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 14,
      ),
    );
  }
}
