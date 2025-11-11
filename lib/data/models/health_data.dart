import 'package:flutter/material.dart';
import '../../core/enums/app_enums.dart';

class HealthData {
  final DateTime date;
  final int spo2; // Saturation O₂ (95-100%)
  final int breathingRate; // Fréquence respiratoire (12-20 bpm)
  final double pef; // Débit de pointe (L/min)
  final List<String> symptoms;
  final RiskLevel riskLevel;

  HealthData({
    required this.date,
    required this.spo2,
    required this.breathingRate,
    required this.pef,
    required this.symptoms,
    required this.riskLevel,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      date: DateTime.parse(json['date']),
      spo2: json['spo2'],
      breathingRate: json['breathing_rate'],
      pef: json['pef'].toDouble(),
      symptoms: List<String>.from(json['symptoms']),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.low,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'spo2': spo2,
      'breathing_rate': breathingRate,
      'pef': pef,
      'symptoms': symptoms,
      'risk_level': riskLevel.name,
    };
  }

  Color getRiskColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Vert
      case RiskLevel.medium:
        return const Color(0xFFFF9800); // Orange
      case RiskLevel.high:
        return const Color(0xFFF44336); // Rouge
    }
  }

  IconData getRiskIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  String getRiskText() {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Risque faible';
      case RiskLevel.medium:
        return 'Risque modéré';
      case RiskLevel.high:
        return 'Risque élevé';
    }
  }

  // Méthodes pour vérifier les valeurs normales
  bool get isSpo2Normal => spo2 >= 95;
  bool get isBreathingRateNormal => breathingRate >= 12 && breathingRate <= 20;
  bool get isPefNormal => pef >= 350;
  
  bool get hasAnyAbnormalValue => !isSpo2Normal || !isBreathingRateNormal || !isPefNormal;
}


