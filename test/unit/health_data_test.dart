import 'package:flutter_test/flutter_test.dart';
import 'package:dalys/data/models/health_data.dart';
import 'package:dalys/core/enums/app_enums.dart';
import 'package:flutter/material.dart';

void main() {
  group('HealthData Model Tests', () {
    test('Create HealthData with normal values', () {
      final healthData = HealthData(
        date: DateTime(2025, 12, 2),
        spo2: 98,
        breathingRate: 16,
        pef: 450,
        temperature: 37.0,
        humidity: 50.0,
        envTemperature: 25.0,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.spo2, 98);
      expect(healthData.breathingRate, 16);
      expect(healthData.pef, 450);
      expect(healthData.temperature, 37.0);
      expect(healthData.riskLevel, RiskLevel.low);
    });

    test('isSpo2Normal returns true for normal values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 97,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.isSpo2Normal, true);
    });

    test('isSpo2Normal returns false for low values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 92,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.high,
      );

      expect(healthData.isSpo2Normal, false);
    });

    test('isBreathingRateNormal returns true for normal values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.isBreathingRateNormal, true);
    });

    test('isBreathingRateNormal returns false for high values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 25,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.medium,
      );

      expect(healthData.isBreathingRateNormal, false);
    });

    test('isPefNormal returns true for normal values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.isPefNormal, true);
    });

    test('isPefNormal returns false for low values', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 300,
        symptoms: [],
        riskLevel: RiskLevel.medium,
      );

      expect(healthData.isPefNormal, false);
    });

    test('hasAnyAbnormalValue returns true when SpO2 is low', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 92,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.high,
      );

      expect(healthData.hasAnyAbnormalValue, true);
    });

    test('hasAnyAbnormalValue returns false when all values are normal', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.hasAnyAbnormalValue, false);
    });

    test('getRiskColor returns green for low risk', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      expect(healthData.getRiskColor(), const Color(0xFF4CAF50));
    });

    test('getRiskColor returns orange for medium risk', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 94,
        breathingRate: 16,
        pef: 340,
        symptoms: [],
        riskLevel: RiskLevel.medium,
      );

      expect(healthData.getRiskColor(), const Color(0xFFFF9800));
    });

    test('getRiskColor returns red for high risk', () {
      final healthData = HealthData(
        date: DateTime.now(),
        spo2: 88,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.high,
      );

      expect(healthData.getRiskColor(), const Color(0xFFF44336));
    });

    test('getRiskIcon returns correct icon for each risk level', () {
      final lowRisk = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      final mediumRisk = HealthData(
        date: DateTime.now(),
        spo2: 94,
        breathingRate: 16,
        pef: 340,
        symptoms: [],
        riskLevel: RiskLevel.medium,
      );

      final highRisk = HealthData(
        date: DateTime.now(),
        spo2: 88,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.high,
      );

      expect(lowRisk.getRiskIcon(), Icons.check_circle);
      expect(mediumRisk.getRiskIcon(), Icons.warning);
      expect(highRisk.getRiskIcon(), Icons.error);
    });

    test('getRiskText returns correct text for each risk level', () {
      final lowRisk = HealthData(
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      final mediumRisk = HealthData(
        date: DateTime.now(),
        spo2: 94,
        breathingRate: 16,
        pef: 340,
        symptoms: [],
        riskLevel: RiskLevel.medium,
      );

      final highRisk = HealthData(
        date: DateTime.now(),
        spo2: 88,
        breathingRate: 16,
        pef: 400,
        symptoms: [],
        riskLevel: RiskLevel.high,
      );

      expect(lowRisk.getRiskText(), 'Risque faible');
      expect(mediumRisk.getRiskText(), 'Risque modéré');
      expect(highRisk.getRiskText(), 'Risque élevé');
    });

    test('toJson serializes correctly', () {
      final healthData = HealthData(
        date: DateTime(2025, 12, 2, 10, 30),
        spo2: 98,
        breathingRate: 16,
        pef: 450,
        temperature: 37.0,
        humidity: 50.0,
        envTemperature: 25.0,
        symptoms: ['toux'],
        riskLevel: RiskLevel.low,
      );

      final json = healthData.toJson();

      expect(json['spo2'], 98);
      expect(json['breathing_rate'], 16);
      expect(json['pef'], 450);
      expect(json['temperature'], 37.0);
      expect(json['humidity'], 50.0);
      expect(json['env_temperature'], 25.0);
      expect(json['symptoms'], ['toux']);
      expect(json['risk_level'], 'low');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'date': '2025-12-02T10:30:00.000',
        'spo2': 98,
        'breathing_rate': 16,
        'pef': 450.0,
        'temperature': 37.0,
        'humidity': 50.0,
        'env_temperature': 25.0,
        'symptoms': ['toux', 'fatigue'],
        'risk_level': 'medium',
      };

      final healthData = HealthData.fromJson(json);

      expect(healthData.spo2, 98);
      expect(healthData.breathingRate, 16);
      expect(healthData.pef, 450.0);
      expect(healthData.temperature, 37.0);
      expect(healthData.humidity, 50.0);
      expect(healthData.envTemperature, 25.0);
      expect(healthData.symptoms, ['toux', 'fatigue']);
      expect(healthData.riskLevel, RiskLevel.medium);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'date': '2025-12-02T10:30:00.000',
        'spo2': 98,
        'breathing_rate': 16,
        'pef': 450.0,
        'symptoms': [],
        'risk_level': 'low',
      };

      final healthData = HealthData.fromJson(json);

      expect(healthData.temperature, null);
      expect(healthData.humidity, null);
      expect(healthData.envTemperature, null);
    });
  });
}
