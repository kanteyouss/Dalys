import 'package:sqflite/sqflite.dart';
import '../models/health_data.dart';
import '../services/database_service.dart';

class HealthRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertHealthData(HealthData data) async {
    final db = await _databaseService.database;
    // Conversion manuelle car le modèle HealthData a des champs complexes
    final map = data.toJson();

    // Adaptation pour SQLite
    final dbMap = {
      'user_id': map['user_id'],
      'date': map['date'],
      'spo2': map['spo2'],
      'breathing_rate': map['breathing_rate'],
      'pef': map['pef'],
      'temperature': map['temperature'],
      'humidity': map['humidity'],
      'env_temperature': map['env_temperature'],
      'symptoms':
          (map['symptoms'] as List).join(','), // Stockage sous forme de chaîne
      'risk_level': map['risk_level'],
    };

    return await db.insert('health_data', dbMap);
  }

  Future<List<HealthData>> getHealthData(
      {required int userId, int limit = 50, int offset = 0}) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];

      // Reconstruction du modèle depuis la DB
      return HealthData.fromJson({
        'user_id': map['user_id'],
        'date': map['date'],
        'spo2': map['spo2'],
        'breathing_rate': map['breathing_rate'],
        'pef': map['pef'],
        'temperature': map['temperature'],
        'humidity': map['humidity'],
        'env_temperature': map['env_temperature'],
        'symptoms': (map['symptoms'] as String).isEmpty
            ? <String>[]
            : (map['symptoms'] as String).split(','),
        'risk_level': map['risk_level'],
      });
    });
  }

  Future<HealthData?> getLatestHealthData(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return HealthData.fromJson({
      'user_id': map['user_id'],
      'date': map['date'],
      'spo2': map['spo2'],
      'breathing_rate': map['breathing_rate'],
      'pef': map['pef'],
      'temperature': map['temperature'],
      'humidity': map['humidity'],
      'env_temperature': map['env_temperature'],
      'symptoms': (map['symptoms'] as String).isEmpty
          ? <String>[]
          : (map['symptoms'] as String).split(','),
      'risk_level': map['risk_level'],
    });
  }
}
