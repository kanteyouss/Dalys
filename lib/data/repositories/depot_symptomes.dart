import 'package:sqflite/sqflite.dart';
import '../models/entree_symptome_quotidien.dart';
import '../services/database_service.dart';

/// Dépôt pour la persistance des symptômes
class DepotSymptomes {
  final DatabaseService _databaseService = DatabaseService();

  /// Sauvegarde une entrée de symptômes
  Future<void> sauvegarderEntree(EntreeSymptomeQuotidien entree) async {
    final db = await _databaseService.database;
    await db.insert(
      'entree_symptomes',
      entree.versMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère l'historique des symptômes sur une période pour un utilisateur
  Future<List<EntreeSymptomeQuotidien>> recupererHistorique({
    required int userId,
    required DateTime debut,
    required DateTime fin,
  }) async {
    final db = await _databaseService.database;
    final resultats = await db.query(
      'entree_symptomes',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, debut.toIso8601String(), fin.toIso8601String()],
      orderBy: 'date DESC',
    );

    return resultats
        .map((map) => EntreeSymptomeQuotidien.depuisMap(map))
        .toList();
  }

  /// Récupère l'entrée d'aujourd'hui si elle existe pour un utilisateur
  Future<EntreeSymptomeQuotidien?> recupererEntreeAujourdhui(int userId) async {
    final now = DateTime.now();
    final debutJournee = DateTime(now.year, now.month, now.day);
    final finJournee = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final historique = await recupererHistorique(
        userId: userId, debut: debutJournee, fin: finJournee);

    if (historique.isNotEmpty) {
      return historique.first;
    }
    return null;
  }

  /// Supprime une entrée par ID
  Future<void> supprimerEntree(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'entree_symptomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
