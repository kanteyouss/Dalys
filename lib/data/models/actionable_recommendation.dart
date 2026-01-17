/// Recommandation actionnable avec timing précis
class ActionableRecommendation {
  final String id;
  final String action;
  final DateTime deadline;
  final Duration estimatedDuration;
  final bool isCritical;
  final String successCriteria;
  final String category; // 'medication', 'exercise', 'lifestyle', 'monitoring', 'consultation'
  final int priority; // 1-10
  final bool completed;
  final DateTime? completedAt;

  ActionableRecommendation({
    String? id,
    required this.action,
    required this.deadline,
    required this.estimatedDuration,
    required this.isCritical,
    required this.successCriteria,
    required this.category,
    required this.priority,
    this.completed = false,
    this.completedAt,
  }) : id = id ?? 'action_${DateTime.now().millisecondsSinceEpoch}';

  /// Retourne true si la deadline est dépassée
  bool get isOverdue => DateTime.now().isAfter(deadline) && !completed;

  /// Retourne le temps restant avant deadline
  Duration get timeRemaining => deadline.difference(DateTime.now());

  /// Retourne un libellé du temps restant
  String get timeRemainingLabel {
    if (completed) return 'Complété';
    if (isOverdue) return 'En retard';

    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    if (hours > 24) {
      final days = (hours / 24).floor();
      return 'Dans $days jour${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Dans $hours heure${hours > 1 ? 's' : ''}';
    } else {
      return 'Dans $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  ActionableRecommendation copyWith({
    String? action,
    DateTime? deadline,
    Duration? estimatedDuration,
    bool? isCritical,
    String? successCriteria,
    String? category,
    int? priority,
    bool? completed,
    DateTime? completedAt,
  }) {
    return ActionableRecommendation(
      id: id,
      action: action ?? this.action,
      deadline: deadline ?? this.deadline,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isCritical: isCritical ?? this.isCritical,
      successCriteria: successCriteria ?? this.successCriteria,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'deadline': deadline.toIso8601String(),
        'estimated_duration_minutes': estimatedDuration.inMinutes,
        'is_critical': isCritical,
        'success_criteria': successCriteria,
        'category': category,
        'priority': priority,
        'completed': completed,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory ActionableRecommendation.fromJson(Map<String, dynamic> json) =>
      ActionableRecommendation(
        id: json['id'],
        action: json['action'],
        deadline: DateTime.parse(json['deadline']),
        estimatedDuration: Duration(minutes: json['estimated_duration_minutes']),
        isCritical: json['is_critical'],
        successCriteria: json['success_criteria'],
        category: json['category'],
        priority: json['priority'],
        completed: json['completed'],
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
      );
}

/// Conseil de prévention personnalisé
class PreventionAdvice {
  final String id;
  final String title;
  final String message;
  final String timing; // Ex: "Aujourd'hui 20h", "Dans 2 jours"
  final String evidence; // Justification basée sur les données
  final List<String>? actions;
  final DateTime timestamp;

  PreventionAdvice({
    String? id,
    required this.title,
    required this.message,
    required this.timing,
    required this.evidence,
    this.actions,
    DateTime? timestamp,
  })  : id = id ?? 'advice_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timing': timing,
        'evidence': evidence,
        'actions': actions,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PreventionAdvice.fromJson(Map<String, dynamic> json) =>
      PreventionAdvice(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timing: json['timing'],
        evidence: json['evidence'],
        actions: json['actions'] != null
            ? List<String>.from(json['actions'])
            : null,
        timestamp: DateTime.parse(json['timestamp']),
      );
}
