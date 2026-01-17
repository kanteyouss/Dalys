import 'package:flutter/material.dart';
import '../../../data/models/comprehensive_forecast_models.dart';
import '../../../data/models/fragility_forecast_models.dart';

/// Widget principal pour afficher les prévisions complètes
class ComprehensiveForecastCard extends StatelessWidget {
  final ComprehensiveHealthForecast forecast;
  final VoidCallback? onTap;

  const ComprehensiveForecastCard({
    super.key,
    required this.forecast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (forecast.dataPoints == 0) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildGlobalScore(context),
              const SizedBox(height: 16),
              _buildMultiHorizonPreview(context),
              const SizedBox(height: 16),
              _buildTopInsights(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.insights_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Prévisions Avancées',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Collectez plus de données pour débloquer les insights prédictifs',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.auto_awesome, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prévisions IA Avancées',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Analyse basée sur votre historique récent',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildConfidenceBadge(context),
      ],
    );
  }

  Widget _buildConfidenceBadge(BuildContext context) {
    final confidence = forecast.confidence;
    final color = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            forecast.confidenceReason,
            style: TextStyle(
              color: Color.lerp(color, Colors.black, 0.3)!,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalScore(BuildContext context) {
    final score = forecast.globalHealthScore;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _parseColor(score.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _parseColor(score.color).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendance Actuelle',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.psychologicalState.toUpperCase(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _parseColor(score.color),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                    ),
                    Text(
                      forecast.primaryTrigger,
                      style: TextStyle(
                        color: Color.lerp(
                            _parseColor(score.color), Colors.black, 0.4)!,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStateIcon(score),
            ],
          ),
        ),
        if (forecast.actionWindow != null) ...[
          const SizedBox(height: 12),
          _buildActionWindowAlert(context),
        ],
        const SizedBox(height: 12),
        _buildPersonalNormSection(context),
      ],
    );
  }

  Widget _buildActionWindowAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous avez environ ${forecast.actionWindow!.inHours}h pour agir avant la zone critique.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalNormSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              forecast.personalNormComparison,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateIcon(GlobalHealthScore score) {
    IconData icon;
    switch (score.psychologicalState) {
      case 'Stable':
        icon = Icons.check_circle_outline;
        break;
      case 'Vigilance':
        icon = Icons.visibility_outlined;
        break;
      case 'Urgent':
        icon = Icons.warning_amber_rounded;
        break;
      default:
        icon = Icons.analytics_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _parseColor(score.color).withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32,
        color: _parseColor(score.color),
      ),
    );
  }

  Widget _buildMultiHorizonPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prévisions Multi-Horizon',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildHorizonChip(
                '6h', forecast.fragilityForecast.prediction6Hours, Colors.red),
            const SizedBox(width: 8),
            _buildHorizonChip('24h',
                forecast.fragilityForecast.prediction24Hours, Colors.orange),
            const SizedBox(width: 8),
            _buildHorizonChip(
                '7j', forecast.fragilityForecast.prediction7Days, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizonChip(
      String label, FragilityPrediction prediction, Color baseColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: baseColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Color.lerp(baseColor, Colors.black, 0.3)!,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prediction.trendDescription,
              style: TextStyle(
                color: Color.lerp(baseColor, Colors.black, 0.4)!,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInsights(BuildContext context) {
    final topInsights = forecast.personalizedInsights.insights
        .where((i) => i.significance > 0.6)
        .take(2)
        .toList();

    if (topInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights Clés',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...topInsights.map((insight) => _buildInsightChip(insight)),
      ],
    );
  }

  Widget _buildInsightChip(HealthInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getInsightIcon(insight.category),
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          if (insight.actionable)
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          'Mis à jour ${_formatLastUpdate(forecast.generatedAt)}',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Text(
          'Voir détails →',
          style: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // MÉTHODES UTILITAIRES

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData _getInsightIcon(String category) {
    switch (category.toLowerCase()) {
      case 'données':
        return Icons.data_usage;
      case 'évolution':
        return Icons.trending_up;
      case 'patterns':
        return Icons.pattern;
      case 'corrélations':
        return Icons.link;
      case 'prévision':
        return Icons.trending_up;
      default:
        return Icons.lightbulb;
    }
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
