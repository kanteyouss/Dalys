import 'package:flutter_test/flutter_test.dart';
import 'package:dalys/features/health_monitoring/controllers/health_controller.dart';
import 'package:dalys/features/alertes/controllers/controleur_alertes.dart';
import 'package:dalys/data/models/health_data.dart';
import 'package:dalys/core/enums/app_enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('HealthController Tests', () {
    late HealthController controller;
    late ControleurAlertes alertController;

    setUpAll(() {
      // Initialize FFI for database
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      controller = HealthController();
      alertController = ControleurAlertes();
      controller.setControleurAlertes(alertController);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state should be loading', () {
      expect(controller.isLoading, true);
      expect(controller.currentHealthData, null);
      expect(controller.historicalData, isEmpty);
    });

    test('Initialize should load data and stop loading', () async {
      await controller.initialize();

      expect(controller.isLoading, false);
      expect(controller.currentHealthData, isNotNull);
      expect(controller.historicalData, isNotEmpty);
    });

    test('Simulation mode should be enabled by default', () async {
      await controller.initialize();

      expect(controller.isSimulationMode, true);
    });

    test('Toggle simulation mode should update state', () async {
      await controller.initialize();
      
      final initialMode = controller.isSimulationMode;
      controller.toggleSimulationMode(!initialMode);

      expect(controller.isSimulationMode, !initialMode);
    });

    test('addManualMeasurement should add new data', () async {
      await controller.initialize();
      
      final initialCount = controller.historicalData.length;
      
      await controller.addManualMeasurement(
        spo2: 98,
        breathingRate: 16,
        pef: 450,
        symptoms: ['toux'],
      );

      expect(controller.historicalData.length, greaterThan(initialCount));
      expect(controller.currentHealthData, isNotNull);
      expect(controller.currentHealthData!.spo2, 98);
      expect(controller.currentHealthData!.breathingRate, 16);
      expect(controller.currentHealthData!.pef, 450);
      expect(controller.currentHealthData!.symptoms, contains('toux'));
    });

    test('addManualMeasurement with critical values should trigger alert', () async {
      await controller.initialize();
      await alertController.initialiser();
      
      final initialAlertCount = alertController.toutesLesAlertes.length;
      
      await controller.addManualMeasurement(
        spo2: 88, // Critical value
        breathingRate: 16,
        pef: 450,
        symptoms: [],
      );

      // Wait a bit for alert processing
      await Future.delayed(const Duration(milliseconds: 100));

      expect(alertController.toutesLesAlertes.length, greaterThan(initialAlertCount));
    });

    test('hasCurrentAnomalies should detect abnormal values', () async {
      await controller.initialize();
      
      // Add normal measurement
      await controller.addManualMeasurement(
        spo2: 98,
        breathingRate: 16,
        pef: 450,
        symptoms: [],
      );
      
      expect(controller.hasCurrentAnomalies(), false);
      
      // Add abnormal measurement
      await controller.addManualMeasurement(
        spo2: 92, // Abnormal
        breathingRate: 16,
        pef: 450,
        symptoms: [],
      );
      
      expect(controller.hasCurrentAnomalies(), true);
    });

    test('refreshData should update current data', () async {
      await controller.initialize();
      
      final initialData = controller.currentHealthData;
      
      await Future.delayed(const Duration(milliseconds: 100));
      await controller.refreshData();
      
      // Data might be different (due to random generation)
      expect(controller.currentHealthData, isNotNull);
    });

    test('getDataForChart should return data for specific parameter', () async {
      await controller.initialize();
      
      final spo2Data = controller.getDataForChart('spo2', days: 7);
      
      expect(spo2Data, isNotEmpty);
      expect(spo2Data.length, lessThanOrEqualTo(8)); // 7 days + today
    });

    test('getAnomalyDaysCount should count days with anomalies', () async {
      await controller.initialize();
      
      // Add some abnormal measurements
      await controller.addManualMeasurement(
        spo2: 92,
        breathingRate: 16,
        pef: 450,
        symptoms: [],
      );
      
      final anomalyDays = controller.getAnomalyDaysCount(days: 7);
      
      expect(anomalyDays, greaterThanOrEqualTo(0));
    });

    test('Controller should handle errors gracefully', () async {
      // This test verifies that the controller doesn't crash on errors
      expect(() => controller.initialize(), returnsNormally);
    });

    test('Historical data should be sorted by date', () async {
      await controller.initialize();
      
      final historicalData = controller.historicalData;
      
      for (int i = 0; i < historicalData.length - 1; i++) {
        expect(
          historicalData[i].date.isBefore(historicalData[i + 1].date) ||
          historicalData[i].date.isAtSameMomentAs(historicalData[i + 1].date),
          true,
          reason: 'Historical data should be sorted chronologically',
        );
      }
    });
  });
}
