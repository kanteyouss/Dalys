import 'package:flutter/material.dart';
import '../../../data/models/fragility_models.dart';

/// Carte de santé prédictive affichée dans le dashboard
class PredictiveHealthCard extends StatelessWidget {
  final FragilityScore? score;
  final VoidCallback onTap;

  const PredictiveHealthCard({
    super.key,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '🔮 Santé Prédictive',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Icône d'état
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getScoreColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStateIcon(),
                      color: _getScoreColor(),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDescription(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (score!.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        score!.recommendations.first,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor() {
    if (score!.value < 30) {
      return const Color(0xFF4CAF50); // Vert
    } else if (score!.value < 50) {
      return const Color(0xFF8BC34A); // Vert clair
    } else if (score!.value < 70) {
      return const Color(0xFFFFA000); // Orange
    } else if (score!.value < 85) {
      return const Color(0xFFFF6F00); // Orange foncé
    } else {
      return const Color(0xFFE53935); // Rouge
    }
  }

  String _getStatusText() {
    if (score!.value < 30) {
      return 'Excellent';
    } else if (score!.value < 50) {
      return 'Bon';
    } else if (score!.value < 70) {
      return 'Attention';
    } else if (score!.value < 85) {
      return 'Fragile';
    } else {
      return 'Critique';
    }
  }

  String _getDescription() {
    if (score!.value < 30) {
      return 'Votre respiration est stable';
    } else if (score!.value < 50) {
      return 'Continuez vos bonnes habitudes';
    } else if (score!.value < 70) {
      return 'Surveillance recommandée';
    } else if (score!.value < 85) {
      return 'Surveillance renforcée nécessaire';
    } else {
      return 'Consultez rapidement votre médecin';
    }
  }

  IconData _getStateIcon() {
    if (score!.value < 50) {
      return Icons.check_circle_outline;
    } else if (score!.value < 85) {
      return Icons.visibility_outlined;
    } else {
      return Icons.warning_amber_rounded;
    }
  }
}
