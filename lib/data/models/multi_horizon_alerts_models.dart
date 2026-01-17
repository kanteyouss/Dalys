import 'fragility_forecast_models.dart';
import 'long_term_analysis_models.dart';

/// Alertes préventives multi-horizon (6h/24h/7j)
class MultiHorizonAlerts {
  final List<PreventiveAlert> alerts6Hours;
  final List<PreventiveAlert> alerts24Hours;
  final List<PreventiveAlert> alerts7Days;
  final FragilityForecast fragilityForecast;
  final LongTermTrendAnalysis longTermAnalysis;
  final List<StrategicRecommendation> strategicRecommendations;
  final DateTime generatedAt;

  MultiHorizonAlerts({
    required this.alerts6Hours,
    required this.alerts24Hours,
    required this.alerts7Days,
    required this.fragilityForecast,
    required this.longTermAnalysis,
    required this.strategicRecommendations,
    required this.generatedAt,
  });

  factory MultiHorizonAlerts.empty() {
    return MultiHorizonAlerts(
      alerts6Hours: [],
      alerts24Hours: [],
      alerts7Days: [],
      fragilityForecast: FragilityForecast.empty(),
      longTermAnalysis: LongTermTrendAnalysis.insufficient(),
      strategicRecommendations: [],
      generatedAt: DateTime.now(),
    );
  }

  /// Vérifie s'il y a au moins une alerte active
  bool get hasAlerts =>
      alerts6Hours.isNotEmpty ||
      alerts24Hours.isNotEmpty ||
      alerts7Days.isNotEmpty;

  /// Nombre total d'alertes actives
  int get totalAlerts =>
      alerts6Hours.length + alerts24Hours.length + alerts7Days.length;

  /// Alerte la plus critique parmi tous les horizons
  PreventiveAlert? get mostCriticalAlert {
    final allAlerts = [...alerts6Hours, ...alerts24Hours, ...alerts7Days];
    if (allAlerts.isEmpty) return null;

    return allAlerts
        .reduce((a, b) => a.severity.index > b.severity.index ? a : b);
  }

  /// Résumé exécutif de tous les horizons
  String get executiveSummary {
    if (totalAlerts == 0) {
      return 'Aucune alerte préventive. Situation stable sur tous horizons.';
    }

    final critical =
        alerts6Hours.where((a) => a.severity == AlertSeverity.critical).length;
    final high =
        allAlerts.where((a) => a.severity == AlertSeverity.high).length;

    if (critical > 0) {
      return '$critical alerte(s) critique(s) dans les 6h. Action immédiate requise.';
    }
    if (high > 0) {
      return '$high alerte(s) haute priorité détectée(s). Surveillance renforcée.';
    }

    return '$totalAlerts alerte(s) préventive(s). Ajustements recommandés.';
  }

  List<PreventiveAlert> get allAlerts =>
      [...alerts6Hours, ...alerts24Hours, ...alerts7Days];
}

/// Alerte préventive pour un horizon temporel spécifique
class PreventiveAlert {
  final String id;
  final AlertSeverity severity;
  final String timeHorizon;
  final String title;
  final String message;
  final double confidence;
  final List<String> preventiveActions;
  final List<String> riskFactors;
  final DateTime estimatedOnset;
  final String? worstCaseScenario; // Scénario si rien n'est fait

  PreventiveAlert({
    required this.id,
    required this.severity,
    required this.timeHorizon,
    required this.title,
    required this.message,
    required this.confidence,
    required this.preventiveActions,
    required this.riskFactors,
    required this.estimatedOnset,
    this.worstCaseScenario,
  });

  String get severityIcon {
    switch (severity) {
      case AlertSeverity.critical:
        return '🚨';
      case AlertSeverity.high:
        return '⚠️';
      case AlertSeverity.medium:
        return '⚡';
      case AlertSeverity.low:
        return 'ℹ️';
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'CRITIQUE';
      case AlertSeverity.high:
        return 'ÉLEVÉ';
      case AlertSeverity.medium:
        return 'MODÉRÉ';
      case AlertSeverity.low:
        return 'FAIBLE';
    }
  }

  String get confidenceDescription {
    if (confidence > 0.8) return 'Très élevée';
    if (confidence > 0.6) return 'Élevée';
    if (confidence > 0.4) return 'Modérée';
    if (confidence > 0.2) return 'Faible';
    return 'Très faible';
  }

  /// Temps restant avant l'événement prédit
  Duration get timeToOnset => estimatedOnset.difference(DateTime.now());

  String get timeToOnsetDescription {
    final duration = timeToOnset;
    if (duration.inHours < 1) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inDays} jour(s)';
    }
  }
}

/// Sévérité des alertes préventives
enum AlertSeverity { low, medium, high, critical }

/// Recommandation stratégique basée sur l'analyse long-terme
class StrategicRecommendation {
  final String category;
  final String title;
  final String description;
  final List<String> actions;
  final String evidence;
  final bool isBestLever; // Si c'est l'action la plus efficace identifiée

  StrategicRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actions,
    required this.evidence,
    this.isBestLever = false,
  });

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'optimisation hebdomadaire':
        return '📅';
      case 'exercices ciblés':
        return '🫁';
      case 'environnement':
        return '🏠';
      case 'médical':
        return '🩺';
      default:
        return '💡';
    }
  }
}
