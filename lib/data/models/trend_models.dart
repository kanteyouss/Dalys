/// Modèles pour l'analyse de tendances prédictives
library;

/// Alerte basée sur une tendance détectée
class TrendAlert {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final List<String> actions;
  final Duration? preventionWindow;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  TrendAlert({
    String? id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.actions,
    this.preventionWindow,
    DateTime? timestamp,
    this.metadata,
  })  : id = id ?? 'trend_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'severity': severity,
        'title': title,
        'message': message,
        'actions': actions,
        'prevention_window_hours': preventionWindow?.inHours,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory TrendAlert.fromJson(Map<String, dynamic> json) => TrendAlert(
        id: json['id'],
        type: json['type'],
        severity: json['severity'],
        title: json['title'],
        message: json['message'],
        actions: List<String>.from(json['actions'] ?? []),
        preventionWindow: json['prevention_window_hours'] != null
            ? Duration(hours: json['prevention_window_hours'])
            : null,
        timestamp: DateTime.parse(json['timestamp']),
        metadata: json['metadata'],
      );
}

/// Pattern récurrent identifié dans l'historique
class RecurringPattern {
  final String type;
  final String description;
  final int occurrences;
  final double confidence;
  final Map<String, dynamic> parameters;

  RecurringPattern({
    required this.type,
    required this.description,
    required this.occurrences,
    required this.confidence,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'occurrences': occurrences,
        'confidence': confidence,
        'parameters': parameters,
      };

  factory RecurringPattern.fromJson(Map<String, dynamic> json) =>
      RecurringPattern(
        type: json['type'],
        description: json['description'],
        occurrences: json['occurrences'],
        confidence: json['confidence'],
        parameters: json['parameters'],
      );
}

/// Trigger personnel qui déclenche une réaction chez le patient
class PersonalTrigger {
  final String type;
  final double threshold;
  final int delayHours;
  final int occurrences;
  final String? preventiveMedication;
  final List<String> recommendedActions;

  PersonalTrigger({
    required this.type,
    required this.threshold,
    required this.delayHours,
    required this.occurrences,
    this.preventiveMedication,
    required this.recommendedActions,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'threshold': threshold,
        'delay_hours': delayHours,
        'occurrences': occurrences,
        'preventive_medication': preventiveMedication,
        'recommended_actions': recommendedActions,
      };

  factory PersonalTrigger.fromJson(Map<String, dynamic> json) =>
      PersonalTrigger(
        type: json['type'],
        threshold: json['threshold'],
        delayHours: json['delay_hours'],
        occurrences: json['occurrences'],
        preventiveMedication: json['preventive_medication'],
        recommendedActions:
            List<String>.from(json['recommended_actions'] ?? []),
      );
}

/// Risque selon l'heure de la journée
class TimeOfDayRisk {
  final String period; // 'morning', 'afternoon', 'evening', 'night'
  final double riskScore; // 0-100
  final String? description;

  TimeOfDayRisk({
    required this.period,
    required this.riskScore,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'period': period,
        'risk_score': riskScore,
        'description': description,
      };

  factory TimeOfDayRisk.fromJson(Map<String, dynamic> json) => TimeOfDayRisk(
        period: json['period'],
        riskScore: json['risk_score'],
        description: json['description'],
      );
}
