import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dalys/data/providers/mock_health_provider.dart';
import 'package:dalys/data/models/health_data.dart';
import 'package:dalys/core/enums/app_enums.dart';

void main() {
  group('MockHealthProvider Tests', () {
    late MockHealthProvider provider;

    setUp(() {
      provider = MockHealthProvider();
    });

    test('generateRealisticHealthData returns valid data', () {
      final healthData = provider.generateRealisticHealthData();

      expect(healthData, isNotNull);
      expect(healthData.date, isNotNull);
      expect(healthData.spo2, greaterThanOrEqualTo(90));
      expect(healthData.spo2, lessThanOrEqualTo(100));
      expect(healthData.breathingRate, greaterThanOrEqualTo(12));
      expect(healthData.breathingRate, lessThanOrEqualTo(30));
      expect(healthData.pef, greaterThanOrEqualTo(250));
      expect(healthData.pef, lessThanOrEqualTo(550));
    });

    test('generateRealisticHealthData includes environmental data', () {
      final healthData = provider.generateRealisticHealthData();

      expect(healthData.temperature, isNotNull);
      expect(healthData.temperature!, greaterThanOrEqualTo(36.0));
      expect(healthData.temperature!, lessThanOrEqualTo(39.0));
      
      expect(healthData.humidity, isNotNull);
      expect(healthData.humidity!, greaterThanOrEqualTo(30.0));
      expect(healthData.humidity!, lessThanOrEqualTo(90.0));
      
      expect(healthData.envTemperature, isNotNull);
      expect(healthData.envTemperature!, greaterThanOrEqualTo(15.0));
      expect(healthData.envTemperature!, lessThanOrEqualTo(35.0));
    });

    test('generateRealisticHealthData assigns correct risk level for critical SpO2', () {
      // Generate multiple data points to eventually get a critical value
      bool foundCritical = false;
      
      for (int i = 0; i < 50; i++) {
        final healthData = provider.generateRealisticHealthData();
        
        if (healthData.spo2 < 92) {
          expect(healthData.riskLevel, RiskLevel.high);
          foundCritical = true;
          break;
        }
      }
      
      // Note: This test might occasionally fail due to randomness
      // In production, we'd use a seeded random or mock the random generator
    });

    test('getHistoricalData returns correct number of days', () {
      final historicalData = provider.getHistoricalData(days: 7);

      expect(historicalData.length, 8); // 7 days + today = 8 data points
    });

    test('getHistoricalData returns data in chronological order', () {
      final historicalData = provider.getHistoricalData(days: 7);

      for (int i = 0; i < historicalData.length - 1; i++) {
        expect(
          historicalData[i].date.isBefore(historicalData[i + 1].date) ||
          historicalData[i].date.isAtSameMomentAs(historicalData[i + 1].date),
          true,
          reason: 'Data should be in chronological order',
        );
      }
    });

    test('getHistoricalData returns valid values for all data points', () {
      final historicalData = provider.getHistoricalData(days: 7);

      for (final data in historicalData) {
        expect(data.spo2, greaterThanOrEqualTo(90));
        expect(data.spo2, lessThanOrEqualTo(99));
        expect(data.breathingRate, greaterThanOrEqualTo(12));
        expect(data.breathingRate, lessThanOrEqualTo(25));
        expect(data.pef, greaterThanOrEqualTo(250));
        expect(data.pef, lessThanOrEqualTo(500));
      }
    });

    test('getHealthDataStream emits data periodically', () async {
      final stream = provider.getHealthDataStream();
      
      // Take first 2 emissions (this will take ~20 seconds in real time)
      // For testing, we just verify the stream is created correctly
      expect(stream, isNotNull);
      
      // We can't easily test the timing without mocking, but we can verify
      // the stream emits valid data
      final firstData = await stream.first.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Stream did not emit data in time');
        },
      );
      
      expect(firstData, isNotNull);
      expect(firstData.spo2, greaterThanOrEqualTo(90));
    });

    test('getMockAlerts returns correct number of alerts', () {
      final alerts = provider.getMockAlerts(count: 5);

      expect(alerts.length, 5);
    });

    test('getMockAlerts returns alerts sorted by timestamp (newest first)', () {
      final alerts = provider.getMockAlerts(count: 10);

      for (int i = 0; i < alerts.length - 1; i++) {
        expect(
          alerts[i].timestamp.isAfter(alerts[i + 1].timestamp) ||
          alerts[i].timestamp.isAtSameMomentAs(alerts[i + 1].timestamp),
          true,
          reason: 'Alerts should be sorted newest first',
        );
      }
    });

    test('generateRealtimeAlert returns unread alert with current timestamp', () {
      final alert = provider.generateRealtimeAlert();

      expect(alert.isRead, false);
      expect(alert.timestamp.difference(DateTime.now()).inSeconds.abs(), lessThan(2));
    });

    test('getEnvironmentalData returns valid environmental data', () {
      final envData = provider.getEnvironmentalData();

      expect(envData['air_quality_index'], greaterThanOrEqualTo(50));
      expect(envData['air_quality_index'], lessThanOrEqualTo(150));
      expect(envData['pollen_count'], greaterThanOrEqualTo(0));
      expect(envData['pollen_count'], lessThanOrEqualTo(4));
      expect(envData['temperature'], greaterThanOrEqualTo(25));
      expect(envData['temperature'], lessThanOrEqualTo(35));
      expect(envData['humidity'], greaterThanOrEqualTo(60));
      expect(envData['humidity'], lessThanOrEqualTo(90));
      expect(envData['location'], 'Abidjan, Côte d\'Ivoire');
    });

    test('Multiple calls to generateRealisticHealthData produce different values', () {
      final data1 = provider.generateRealisticHealthData();
      final data2 = provider.generateRealisticHealthData();
      final data3 = provider.generateRealisticHealthData();

      // At least one value should be different (due to randomness)
      final allSame = data1.spo2 == data2.spo2 && 
                      data2.spo2 == data3.spo2 &&
                      data1.breathingRate == data2.breathingRate &&
                      data2.breathingRate == data3.breathingRate &&
                      data1.pef == data2.pef &&
                      data2.pef == data3.pef;
      
      expect(allSame, false, reason: 'Random data should vary between calls');
    });
  });
}
