import 'package:flutter/material.dart';

enum TypeSuggestion {
  prevention, // Prévention (vert)
  action,     // Action requise (orange)
  alert,      // Alerte critique (rouge)
}

class Suggestion {
  final String id;
  final String title;
  final String description;
  final TypeSuggestion type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: TypeSuggestion.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TypeSuggestion.prevention,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  Color get color {
    switch (type) {
      case TypeSuggestion.prevention:
        return Colors.green;
      case TypeSuggestion.action:
        return Colors.orange;
      case TypeSuggestion.alert:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (type) {
      case TypeSuggestion.prevention:
        return Icons.lightbulb_outline;
      case TypeSuggestion.action:
        return Icons.directions_run;
      case TypeSuggestion.alert:
        return Icons.warning_amber_rounded;
    }
  }
}
