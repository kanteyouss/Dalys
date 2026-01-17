import 'package:flutter/material.dart';
import '../../../data/models/multi_horizon_alerts_models.dart';

/// Widget pour afficher les alertes préventives multi-horizon
class MultiHorizonAlertsWidget extends StatelessWidget {
  final MultiHorizonAlerts alerts;
  final VoidCallback? onViewDetails;

  const MultiHorizonAlertsWidget({
    super.key,
    required this.alerts,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final allAlerts = [
      ...alerts.alerts6Hours,
      ...alerts.alerts24Hours,
      ...alerts.alerts7Days,
    ];

    if (allAlerts.isEmpty) {
      return _buildNoAlertsCard(context);
    }

    final criticalAlerts =
        allAlerts.where((a) => a.severity == AlertSeverity.high).toList();
    final importantAlerts =
        allAlerts.where((a) => a.severity == AlertSeverity.medium).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, allAlerts.length),
        const SizedBox(height: 12),

        // Alertes critiques en premier
        if (criticalAlerts.isNotEmpty) ...[
          _buildAlertGroup(
              context, 'Actions Prioritaires', criticalAlerts, Colors.red),
          const SizedBox(height: 12),
        ],

        // Alertes importantes
        if (importantAlerts.isNotEmpty) ...[
          _buildAlertGroup(
              context, 'À Surveiller', importantAlerts, Colors.orange),
          const SizedBox(height: 12),
        ],

        // Recommandations stratégiques
        if (alerts.strategicRecommendations.isNotEmpty) ...[
          _buildStrategicRecommendations(context),
        ],
      ],
    );
  }

  Widget _buildNoAlertsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pas d\'alerte active',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                  ),
                  Text(
                    'Tous vos indicateurs sont dans les normes prévues',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalAlerts) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber, color: Colors.orange.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conseils de Vigilance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$totalAlerts point${totalAlerts > 1 ? 's' : ''} d\'attention',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (onViewDetails != null)
          TextButton(
            onPressed: onViewDetails,
            child: const Text('Voir tout'),
          ),
      ],
    );
  }

  Widget _buildAlertGroup(BuildContext context, String title,
      List<PreventiveAlert> groupAlerts, Color baseColor) {
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
                Icon(Icons.priority_high, color: baseColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Color.lerp(baseColor, Colors.black, 0.3)!,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...groupAlerts
                .take(3)
                .map((alert) => _buildAlertItem(context, alert, baseColor)),
            if (groupAlerts.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${groupAlerts.length - 3} autre${groupAlerts.length - 3 > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(
      BuildContext context, PreventiveAlert alert, Color baseColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color.lerp(baseColor, Colors.black, 0.4)!,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildTimeToOnset(alert, baseColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            alert.message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          if (alert.preventiveActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.preventiveActions.first,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (alert.worstCaseScenario != null) ...[
            const SizedBox(height: 8),
            Text(
              '🔮 Scénario : ${alert.worstCaseScenario}',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeToOnset(PreventiveAlert alert, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatOnset(alert),
        style: TextStyle(
          color: Color.lerp(baseColor, Colors.black, 0.3)!,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStrategicRecommendations(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.psychology,
                      color: Colors.purple.shade600, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommandations Stratégiques',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.strategicRecommendations
                .take(2)
                .map((rec) => _buildStrategicRecommendation(context, rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategicRecommendation(
      BuildContext context, StrategicRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRecommendationIcon(recommendation.category),
                size: 16,
                color: Colors.purple.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildImpactBadge(_inferImpact(recommendation)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          if (recommendation.isBestLever) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  const Text(
                    'MEILLEUR LEVIER D\'AMÉLIORATION',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildImpactBadge(String impact) {
    final color = impact == 'élevé'
        ? Colors.green
        : impact == 'modéré'
            ? Colors.orange
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        impact,
        style: TextStyle(
          color: Color.lerp(color, Colors.black, 0.3)!,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatOnset(PreventiveAlert alert) {
    final d = alert.timeToOnset;
    if (d.inHours < 1) return '<1h';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}j';
  }

  String _inferImpact(StrategicRecommendation rec) {
    final n = rec.actions.length;
    if (n >= 3) return 'élevé';
    if (n == 2) return 'modéré';
    return 'faible';
  }

  IconData _getRecommendationIcon(String category) {
    switch (category.toLowerCase()) {
      case 'lifestyle':
        return Icons.health_and_safety;
      case 'monitoring':
        return Icons.monitor_heart;
      case 'medical':
        return Icons.medical_services;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.recommend;
    }
  }
}
