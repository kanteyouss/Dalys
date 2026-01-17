/// Modèles pour le score de fragilité
library;

/// Score de fragilité du patient (0-100)
class FragilityScore {
  final double value; // 0-100
  final FragilityLevel level;
  final List<RiskFactor> factors;
  final Duration nextReviewIn;
  final List<String> recommendations;
  final DateTime timestamp;

  FragilityScore({
    required this.value,
    required this.level,
    required this.factors,
    required this.nextReviewIn,
    required this.recommendations,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'value': value,
        'level': level.name,
        'factors': factors.map((f) => f.toJson()).toList(),
        'next_review_hours': nextReviewIn.inHours,
        'recommendations': recommendations,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FragilityScore.fromJson(Map<String, dynamic> json) => FragilityScore(
        value: json['value'],
        level: FragilityLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => FragilityLevel.stable,
        ),
        factors: (json['factors'] as List)
            .map((f) => RiskFactor.fromJson(f))
            .toList(),
        nextReviewIn: Duration(hours: json['next_review_hours']),
        recommendations: List<String>.from(json['recommendations'] ?? []),
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Facteur contribuant au score de fragilité
class RiskFactor {
  final String name;
  final double contribution; // Points ajoutés au score
  final String explanation;
  final String? evidence; // Données factuelles

  RiskFactor({
    required this.name,
    required this.contribution,
    required this.explanation,
    this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'contribution': contribution,
        'explanation': explanation,
        'evidence': evidence,
      };

  factory RiskFactor.fromJson(Map<String, dynamic> json) => RiskFactor(
        name: json['name'],
        contribution: json['contribution'],
        explanation: json['explanation'],
        evidence: json['evidence'],
      );
}

/// Niveau de fragilité
enum FragilityLevel {
  stable, // 0-19: Tout va bien
  moderate, // 20-39: Vigilance normale
  elevated, // 40-69: Surveillance renforcée
  critical, // 70-100: Phase pré-crise
}

extension FragilityLevelExtension on FragilityLevel {
  String get label {
    switch (this) {
      case FragilityLevel.stable:
        return 'Stable';
      case FragilityLevel.moderate:
        return 'Modéré';
      case FragilityLevel.elevated:
        return 'Élevé';
      case FragilityLevel.critical:
        return 'Critique';
    }
  }

  String get emoji {
    switch (this) {
      case FragilityLevel.stable:
        return '✅';
      case FragilityLevel.moderate:
        return '⚠️';
      case FragilityLevel.elevated:
        return '🔶';
      case FragilityLevel.critical:
        return '🚨';
    }
  }

  String get description {
    switch (this) {
      case FragilityLevel.stable:
        return 'État stable - Continuez vos bonnes habitudes';
      case FragilityLevel.moderate:
        return 'Vigilance normale - Surveillance recommandée';
      case FragilityLevel.elevated:
        return 'État fragile - Surveillance renforcée nécessaire';
      case FragilityLevel.critical:
        return 'État pré-critique - Action immédiate requise';
    }
  }
}
