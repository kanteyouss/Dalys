import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dalys/data/repositories/health_repository.dart';
import 'package:dalys/data/models/health_data.dart';
import 'package:dalys/core/enums/app_enums.dart';

void main() {
  // Setup sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('HealthRepository Data Isolation Test', () {
    late HealthRepository repository;

    setUp(() async {
      // For simplicity in this environment, we just use the singleton
      repository = HealthRepository();
    });

    test('User A should not see User B data', () async {
      const userIdA = 999;
      const userIdB = 888;

      final dataA = HealthData(
        userId: userIdA,
        date: DateTime.now(),
        spo2: 98,
        breathingRate: 16,
        pef: 450,
        symptoms: [],
        riskLevel: RiskLevel.low,
      );

      final dataB = HealthData(
        userId: userIdB,
        date: DateTime.now(),
        spo2: 90,
        breathingRate: 25,
        pef: 300,
        symptoms: ['Toux'],
        riskLevel: RiskLevel.high,
      );

      // Insert data for both users
      await repository.insertHealthData(dataA);
      await repository.insertHealthData(dataB);

      // Fetch data for User A
      final historyA = await repository.getHealthData(userId: userIdA);
      expect(historyA.every((d) => d.userId == userIdA), isTrue);
      expect(historyA.any((d) => d.userId == userIdB), isFalse);

      // Fetch data for User B
      final historyB = await repository.getHealthData(userId: userIdB);
      expect(historyB.every((d) => d.userId == userIdB), isTrue);
      expect(historyB.any((d) => d.userId == userIdA), isFalse);
    });
  });
}
