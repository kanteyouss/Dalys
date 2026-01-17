import 'long_term_analysis_models.dart';
import 'fragility_forecast_models.dart';
import 'multi_horizon_alerts_models.dart';

/// Prévision complète de santé exploitant TOUT l'historique utilisateur
class ComprehensiveHealthForecast {
  final int userId;
  final int dataPoints; // Nombre total de mesures analysées
  final Duration timeSpan; // Période couverte par les données
  final String primaryTrigger; // Cause principale de la tendance
  final Duration? actionWindow; // Temps restant avant zone critique
  final String confidenceReason; // Pourquoi la prévision est fiable ou non
  final String personalNormComparison; // Lien avec les valeurs habituelles
  final LongTermTrendAnalysis longTermAnalysis;
  final FragilityForecast fragilityForecast;
  final MultiHorizonAlerts multiHorizonAlerts;
  final PersonalizedHealthInsights personalizedInsights;
  final GlobalHealthScore globalHealthScore;
  final double confidence; // Confiance globale 0-1
  final DateTime generatedAt;
  final DateTime validUntil;

  const ComprehensiveHealthForecast({
    required this.userId,
    required this.dataPoints,
    required this.timeSpan,
    required this.primaryTrigger,
    this.actionWindow,
    required this.confidenceReason,
    required this.personalNormComparison,
    required this.longTermAnalysis,
    required this.fragilityForecast,
    required this.multiHorizonAlerts,
    required this.personalizedInsights,
    required this.globalHealthScore,
    required this.confidence,
    required this.generatedAt,
    required this.validUntil,
  });

  /// Prévision vide pour utilisateurs sans données
  factory ComprehensiveHealthForecast.empty() {
    return ComprehensiveHealthForecast(
      userId: -1,
      dataPoints: 0,
      timeSpan: const Duration(milliseconds: 0),
      primaryTrigger: 'Données insuffisantes',
      actionWindow: null,
      confidenceReason: 'Analyse en cours de démarrage',
      personalNormComparison: 'Établissement de votre profil de base',
      longTermAnalysis: LongTermTrendAnalysis.insufficient(),
      fragilityForecast: FragilityForecast.empty(),
      multiHorizonAlerts: MultiHorizonAlerts.empty(),
      personalizedInsights: PersonalizedHealthInsights.empty(),
      globalHealthScore: GlobalHealthScore.unknown(),
      confidence: 0.0,
      generatedAt: DateTime.now(),
      validUntil: DateTime.now().add(Duration(hours: 1)),
    );
  }

  /// Vérifie si la prévision est encore valide
  bool get isValid => DateTime.now().isBefore(validUntil);

  /// Vérifie si on a assez de données pour des prédictions fiables
  bool get hasReliableData => dataPoints >= 20 && timeSpan.inDays >= 7;

  /// Résumé exécutif de la prévision
  String get executiveSummary {
    if (dataPoints == 0) {
      return 'Aucune donnée disponible pour générer des prévisions.';
    }

    final scoreDesc = globalHealthScore.interpretation;
    final confidenceDesc = confidence > 0.8
        ? 'très fiable'
        : confidence > 0.6
            ? 'fiable'
            : confidence > 0.4
                ? 'modérée'
                : 'limitée';

    return 'Analyse de $dataPoints mesures sur ${timeSpan.inDays} jours. '
        '$scoreDesc. Confiance $confidenceDesc dans les prédictions.';
  }

  /// Recommandations principales
  List<String> get keyRecommendations {
    final recommendations = <String>[];

    // Recommandations basées sur le score global
    if (globalHealthScore.value < 50) {
      recommendations.add('Consulter un professionnel de santé rapidement');
    }

    // Recommandations des alertes préventives
    final alerts6h = multiHorizonAlerts.alerts6Hours
        .where((a) => a.severity.index >= AlertSeverity.medium.index)
        .toList();
    if (alerts6h.isNotEmpty) {
      recommendations.add('Vigilance accrue dans les 6 prochaines heures');
    }

    // Recommandations des insights personnalisés
    recommendations.addAll(personalizedInsights.insights
        .where((i) => i.actionable && i.action != null)
        .take(3)
        .map((i) => i.action!));

    return recommendations.take(5).toList();
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'dataPoints': dataPoints,
        'timeSpanDays': timeSpan.inDays,
        'confidence': confidence,
        'globalScore': globalHealthScore.value,
        'generatedAt': generatedAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
      };
}

/// Insights de santé personnalisés basés sur l'historique complet
class PersonalizedHealthInsights {
  final List<HealthInsight> insights;
  final double overallPersonalizationScore; // 0-1
  final double dataQualityScore; // 0-1

  const PersonalizedHealthInsights({
    required this.insights,
    required this.overallPersonalizationScore,
    required this.dataQualityScore,
  });

  factory PersonalizedHealthInsights.empty() {
    return const PersonalizedHealthInsights(
      insights: [],
      overallPersonalizationScore: 0.0,
      dataQualityScore: 0.0,
    );
  }

  /// Insights actionnables (avec recommandations)
  List<HealthInsight> get actionableInsights =>
      insights.where((i) => i.actionable).toList();

  /// Insights les plus significatifs
  List<HealthInsight> get significantInsights =>
      insights.where((i) => i.significance > 0.6).toList();

  /// Insights par catégorie
  Map<String, List<HealthInsight>> get insightsByCategory {
    final Map<String, List<HealthInsight>> grouped = {};
    for (final insight in insights) {
      grouped.putIfAbsent(insight.category, () => []).add(insight);
    }
    return grouped;
  }
}

/// Un insight de santé personnalisé
class HealthInsight {
  final String category; // 'Données', 'Évolution', 'Patterns', etc.
  final String title;
  final String description;
  final double significance; // 0-1, importance de cet insight
  final bool actionable; // Si l'utilisateur peut agir dessus
  final String? action; // Action recommandée si actionable

  const HealthInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.significance,
    required this.actionable,
    this.action,
  });

  /// Niveau de priorité basé sur la significance
  InsightPriority get priority {
    if (significance >= 0.8) return InsightPriority.high;
    if (significance >= 0.6) return InsightPriority.medium;
    return InsightPriority.low;
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title,
        'description': description,
        'significance': significance,
        'actionable': actionable,
        'action': action,
        'priority': priority.name,
      };
}

enum InsightPriority { low, medium, high }

/// Score de santé global consolidant toutes les analyses
class GlobalHealthScore {
  final double value; // 0-100
  final HealthScoreLevel level;
  final Map<String, double?> components; // Scores des composants
  final String interpretation;
  final String? baselineComparison; // Comparaison avec la norme personnelle

  const GlobalHealthScore({
    required this.value,
    required this.level,
    required this.components,
    required this.interpretation,
    this.baselineComparison,
  });

  factory GlobalHealthScore.unknown() {
    return const GlobalHealthScore(
      value: 50.0,
      level: HealthScoreLevel.unknown,
      components: {},
      interpretation: 'Données insuffisantes pour calculer un score',
      baselineComparison: null,
    );
  }

  /// Évolution par rapport à un score précédent
  double calculateEvolution(GlobalHealthScore? previous) {
    if (previous == null) return 0.0;
    return value - previous.value;
  }

  /// Couleur associée au niveau
  String get color {
    switch (level) {
      case HealthScoreLevel.excellent:
        return '#4CAF50'; // Vert
      case HealthScoreLevel.good:
        return '#8BC34A'; // Vert clair
      case HealthScoreLevel.fair:
        return '#FFC107'; // Jaune
      case HealthScoreLevel.poor:
        return '#FF9800'; // Orange
      case HealthScoreLevel.critical:
        return '#F44336'; // Rouge
      case HealthScoreLevel.unknown:
        return '#9E9E9E'; // Gris
    }
  }

  /// Description textuelle du niveau
  String get levelDescription {
    switch (level) {
      case HealthScoreLevel.excellent:
        return 'Excellent';
      case HealthScoreLevel.good:
        return 'Bon';
      case HealthScoreLevel.fair:
        return 'Acceptable';
      case HealthScoreLevel.poor:
        return 'Préoccupant';
      case HealthScoreLevel.critical:
        return 'Critique';
      case HealthScoreLevel.unknown:
        return 'Inconnu';
    }
  }

  /// État psychologique simplifié pour l'utilisateur
  String get psychologicalState {
    switch (level) {
      case HealthScoreLevel.excellent:
      case HealthScoreLevel.good:
        return 'Stable';
      case HealthScoreLevel.fair:
      case HealthScoreLevel.poor:
        return 'Vigilance';
      case HealthScoreLevel.critical:
        return 'Urgent';
      case HealthScoreLevel.unknown:
        return 'Analyse en cours';
    }
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'level': level.name,
        'levelDescription': levelDescription,
        'interpretation': interpretation,
        'color': color,
        'components': components,
      };
}

enum HealthScoreLevel {
  unknown,
  critical, // 0-35
  poor, // 35-50
  fair, // 50-65
  good, // 65-80
  excellent // 80-100
}
