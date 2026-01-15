import 'package:flutter/material.dart';
import '../../core/enums/app_enums.dart';

class HealthData {
  final int? userId;
  final DateTime date;
  final int spo2; // Saturation O₂ (95-100%)
  final int breathingRate; // Fréquence respiratoire (12-20 bpm)
  final double pef; // Débit de pointe (L/min)
  final double? temperature; // Température corporelle (DS18B20)
  final double? humidity; // Humidité ambiante (DHT22)
  final double? envTemperature; // Température ambiante (DHT22)
  final List<String> symptoms;
  final RiskLevel riskLevel;

  HealthData({
    this.userId,
    required this.date,
    required this.spo2,
    required this.breathingRate,
    required this.pef,
    this.temperature,
    this.humidity,
    this.envTemperature,
    required this.symptoms,
    required this.riskLevel,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      spo2: json['spo2'],
      breathingRate: json['breathing_rate'],
      pef: json['pef'].toDouble(),
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      envTemperature: json['env_temperature']?.toDouble(),
      symptoms: List<String>.from(json['symptoms']),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.low,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String(),
      'spo2': spo2,
      'breathing_rate': breathingRate,
      'pef': pef,
      'temperature': temperature,
      'humidity': humidity,
      'env_temperature': envTemperature,
      'symptoms': symptoms,
      'risk_level': riskLevel.name,
    };
  }

  HealthData copyWith({
    int? userId,
    DateTime? date,
    int? spo2,
    int? breathingRate,
    double? pef,
    double? temperature,
    double? humidity,
    double? envTemperature,
    List<String>? symptoms,
    RiskLevel? riskLevel,
  }) {
    return HealthData(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      spo2: spo2 ?? this.spo2,
      breathingRate: breathingRate ?? this.breathingRate,
      pef: pef ?? this.pef,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      envTemperature: envTemperature ?? this.envTemperature,
      symptoms: symptoms ?? this.symptoms,
      riskLevel: riskLevel ?? this.riskLevel,
    );
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

  bool get hasAnyAbnormalValue =>
      !isSpo2Normal || !isBreathingRateNormal || !isPefNormal;
}
