import 'fragility_models.dart';
import 'long_term_analysis_models.dart';

/// Prévision complète de fragilité avec multi-horizon
class FragilityForecast {
  final FragilityScore currentScore;
  final FragilityPrediction prediction6Hours;
  final FragilityPrediction prediction24Hours;
  final FragilityPrediction prediction7Days;
  final LongTermTrendAnalysis longTermAnalysis;
  final List<PreventiveRecommendation> preventiveRecommendations;
  final double confidence;
  final DateTime generatedAt;

  FragilityForecast({
    required this.currentScore,
    required this.prediction6Hours,
    required this.prediction24Hours,
    required this.prediction7Days,
    required this.longTermAnalysis,
    required this.preventiveRecommendations,
    required this.confidence,
    required this.generatedAt,
  });

  factory FragilityForecast.empty() {
    return FragilityForecast(
      currentScore: FragilityScore(
        value: 25,
        level: FragilityLevel.moderate,
        factors: [],
        nextReviewIn: Duration(hours: 24),
        recommendations: [],
      ),
      prediction6Hours: FragilityPrediction.low(confidence: 0.0),
      prediction24Hours: FragilityPrediction.low(confidence: 0.0),
      prediction7Days: FragilityPrediction.low(confidence: 0.0),
      longTermAnalysis: LongTermTrendAnalysis.insufficient(),
      preventiveRecommendations: [],
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }

  /// Niveau de risque le plus élevé parmi toutes les prédictions
  FragilityLevel get maxRiskLevel {
    final levels = [
      currentScore.level,
      prediction6Hours.predictedLevel,
      prediction24Hours.predictedLevel,
      prediction7Days.predictedLevel,
    ];

    if (levels.contains(FragilityLevel.critical))
      return FragilityLevel.critical;
    if (levels.contains(FragilityLevel.elevated))
      return FragilityLevel.elevated;
    if (levels.contains(FragilityLevel.moderate))
      return FragilityLevel.moderate;
    return FragilityLevel.stable;
  }

  /// Résumé exécutif de la prévision
  String get executiveSummary {
    final maxLevel = maxRiskLevel;
    final timeToRisk = _getTimeToMaxRisk();

    switch (maxLevel) {
      case FragilityLevel.critical:
        return 'Risque critique prévu $timeToRisk. Action immédiate recommandée.';
      case FragilityLevel.elevated:
        return 'Risque élevé prévu $timeToRisk. Surveillance renforcée nécessaire.';
      case FragilityLevel.moderate:
        return 'Risque modéré prévu $timeToRisk. Maintenir vigilance habituelle.';
      case FragilityLevel.stable:
        return 'État stable prévu sur tous horizons. Continuer routine actuelle.';
    }
  }

  String _getTimeToMaxRisk() {
    if (currentScore.level == maxRiskLevel) return 'actuellement';
    if (prediction6Hours.predictedLevel == maxRiskLevel) return 'dans 6h';
    if (prediction24Hours.predictedLevel == maxRiskLevel) return 'dans 24h';
    if (prediction7Days.predictedLevel == maxRiskLevel) return 'dans 7j';
    return 'à déterminer';
  }
}

/// Prédiction de fragilité pour un horizon temporel donné
class FragilityPrediction {
  final double predictedScore;
  final FragilityLevel predictedLevel;
  final double confidence;
  final List<String> riskFactors;
  final String timeHorizon;
  final String? worstCaseScenario; // Scénario si rien n'est fait

  FragilityPrediction({
    required this.predictedScore,
    required this.predictedLevel,
    required this.confidence,
    required this.riskFactors,
    required this.timeHorizon,
    this.worstCaseScenario,
  });

  factory FragilityPrediction.low({required double confidence}) {
    return FragilityPrediction(
      predictedScore: 15.0,
      predictedLevel: FragilityLevel.stable,
      confidence: confidence,
      riskFactors: [],
      timeHorizon: 'non spécifié',
      worstCaseScenario: null,
    );
  }

  String get confidenceDescription {
    if (confidence > 0.8) return 'Très élevée';
    if (confidence > 0.6) return 'Élevée';
    if (confidence > 0.4) return 'Modérée';
    if (confidence > 0.2) return 'Faible';
    return 'Très faible';
  }

  String get riskDescription {
    if (riskFactors.isEmpty) return 'Aucun facteur de risque identifié';
    if (riskFactors.length == 1) return riskFactors.first;
    return '${riskFactors.length} facteurs de risque détectés';
  }

  /// Description humaine de la tendance
  String get trendDescription {
    if (predictedScore < 30) return 'Amélioration probable';
    if (predictedScore < 60) return 'Stabilité prévue';
    return 'Dégradation possible';
  }
}

/// Recommandation préventive
class PreventiveRecommendation {
  final RecommendationPriority priority;
  final String timeframe;
  final String title;
  final String description;
  final List<String> actions;
  final bool isBestLever; // Si c'est l'action la plus efficace identifiée

  PreventiveRecommendation({
    required this.priority,
    required this.timeframe,
    required this.title,
    required this.description,
    required this.actions,
    this.isBestLever = false,
  });

  String get priorityIcon {
    switch (priority) {
      case RecommendationPriority.urgent:
        return '🚨';
      case RecommendationPriority.high:
        return '⚠️';
      case RecommendationPriority.medium:
        return '📋';
      case RecommendationPriority.low:
        return 'ℹ️';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case RecommendationPriority.urgent:
        return 'URGENT';
      case RecommendationPriority.high:
        return 'ÉLEVÉ';
      case RecommendationPriority.medium:
        return 'MODÉRÉ';
      case RecommendationPriority.low:
        return 'FAIBLE';
    }
  }
}

/// Priorité des recommandations
enum RecommendationPriority { urgent, high, medium, low }

/// Facteur de risque quotidien
class DailyRiskFactor {
  final double score;
  final String factor;

  DailyRiskFactor({required this.score, required this.factor});

  factory DailyRiskFactor.none() {
    return DailyRiskFactor(score: 0.0, factor: '');
  }
}
