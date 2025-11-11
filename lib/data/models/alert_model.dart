import 'package:flutter/material.dart';
import '../../core/enums/app_enums.dart';

class AlertModel {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final RiskLevel severity;
  final DateTime timestamp;
  final String? recommendation;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.recommendation,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      severity: RiskLevel.values.firstWhere((e) => e.name == json['severity']),
      timestamp: DateTime.parse(json['timestamp']),
      recommendation: json['recommendation'],
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'recommendation': recommendation,
      'is_read': isRead,
    };
  }

  Color getSeverityColor() {
    switch (severity) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Vert
      case RiskLevel.medium:
        return const Color(0xFFFF9800); // Orange
      case RiskLevel.high:
        return const Color(0xFFF44336); // Rouge
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case AlertType.aiPrediction:
        return Icons.psychology;
      case AlertType.environmental:
        return Icons.cloud;
      case AlertType.healthAnomaly:
        return Icons.health_and_safety;
    }
  }

  String getTypeText() {
    switch (type) {
      case AlertType.aiPrediction:
        return 'Prédiction IA';
      case AlertType.environmental:
        return 'Environnemental';
      case AlertType.healthAnomaly:
        return 'Anomalie santé';
    }
  }

  AlertModel copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    RiskLevel? severity,
    DateTime? timestamp,
    String? recommendation,
    bool? isRead,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      recommendation: recommendation ?? this.recommendation,
      isRead: isRead ?? this.isRead,
    );
  }
}

