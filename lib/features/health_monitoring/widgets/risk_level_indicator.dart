import 'package:flutter/material.dart';
import '../../../core/enums/app_enums.dart';

class RiskLevelIndicator extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool showText;
  final double size;

  const RiskLevelIndicator({
    super.key,
    required this.riskLevel,
    this.showText = true,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();
    final icon = _getRiskIcon();
    final text = _getRiskText();
    final description = _getRiskDescription();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 3),
              ),
              child: Icon(
                icon,
                size: size * 0.5,
                color: color,
              ),
            ),
            if (showText) ...[
              const SizedBox(height: 16),
              Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRiskColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Vert
      case RiskLevel.medium:
        return const Color(0xFFFF9800); // Orange
      case RiskLevel.high:
        return const Color(0xFFF44336); // Rouge
    }
  }

  IconData _getRiskIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  String _getRiskText() {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Risque Faible';
      case RiskLevel.medium:
        return 'Risque Modéré';
      case RiskLevel.high:
        return 'Risque Élevé';
    }
  }

  String _getRiskDescription() {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Vos paramètres vitaux sont dans les normes. Continuez vos bonnes habitudes !';
      case RiskLevel.medium:
        return 'Attention : certains paramètres nécessitent surveillance. Restez vigilant.';
      case RiskLevel.high:
        return 'Alerte : paramètres critiques détectés. Consultez rapidement un professionnel de santé.';
    }
  }
}
