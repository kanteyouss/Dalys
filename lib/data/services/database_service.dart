import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dalys_health.db');

    final db = await openDatabase(
      path,
      version: 9, // Augmentation pour les nouveaux modèles prédictifs
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // S'assurer que toutes les tables prédictives existent
    // (résout le problème de tables manquantes après migrations partielles)
    await _createPredictiveTables(db);
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table health_data (Feature 1)
    await db.execute('''
      CREATE TABLE health_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        spo2 INTEGER NOT NULL,
        breathing_rate INTEGER NOT NULL,
        pef REAL NOT NULL,
        temperature REAL,
        humidity REAL,
        env_temperature REAL,
        symptoms TEXT,
        risk_level TEXT NOT NULL
      )
    ''');

    // Nouvelles tables (Feature 4)
    await _createSymptomTables(db);

    // Table Utilisateurs (Authentification)
    await _createUserTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSymptomTables(db);
    }
    if (oldVersion < 3) {
      await _createUserTable(db);
    }
    if (oldVersion < 4) {
      // Ajout de la colonne user_id aux tables existantes
      await db.execute(
          'ALTER TABLE health_data ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          'ALTER TABLE entree_symptomes ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          'ALTER TABLE historique_chat ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 5) {
      await db
          .execute('ALTER TABLE users ADD COLUMN emergency_contact_name TEXT');
      await db
          .execute('ALTER TABLE users ADD COLUMN emergency_contact_phone TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN current_destination TEXT');
    }
    if (oldVersion < 6) {
      await db
          .execute('ALTER TABLE users ADD COLUMN emergency_contact_email TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE users ADD COLUMN doctor_email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN hospital_email TEXT');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE users ADD COLUMN photo_url TEXT');
    }
    if (oldVersion < 9) {
      // Ajout des colonnes de tendance à health_data
      await db.execute('ALTER TABLE health_data ADD COLUMN trend_direction TEXT');
      await db.execute('ALTER TABLE health_data ADD COLUMN variability REAL');
      await db.execute('ALTER TABLE health_data ADD COLUMN deviation_from_baseline REAL');
      await db.execute('ALTER TABLE health_data ADD COLUMN metadata TEXT');
      
      // Nouvelles tables pour le système prédictif
      await _createPredictiveTables(db);
    }
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        telephone TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        emergency_contact_email TEXT,
        doctor_email TEXT,
        hospital_email TEXT,
        photo_url TEXT
      )
    ''');
  }

  Future<void> _createSymptomTables(Database db) async {
    // Table pour l'historique des symptômes quotidiens
    await db.execute('''
      CREATE TABLE entree_symptomes(
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        symptomes TEXT NOT NULL,
        severite TEXT NOT NULL,
        notes_supplementaires TEXT,
        metadonnees TEXT
      )
    ''');

    // Table pour l'historique du chat
    await db.execute('''
      CREATE TABLE historique_chat(
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        texte TEXT NOT NULL,
        est_utilisateur INTEGER NOT NULL,
        type TEXT NOT NULL,
        reponses_rapides TEXT
      )
    ''');
  }
  
  Future<void> _createPredictiveTables(Database db) async {
    // Table pour les profils de risque patients
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_profiles(
        user_id INTEGER PRIMARY KEY,
        baseline_spo2 REAL NOT NULL,
        baseline_breathing_rate INTEGER NOT NULL,
        baseline_pef REAL NOT NULL,
        patterns TEXT,
        triggers TEXT,
        morning_risk TEXT NOT NULL,
        afternoon_risk TEXT NOT NULL,
        evening_risk TEXT NOT NULL,
        night_risk TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        days_analyzed INTEGER NOT NULL
      )
    ''');

    // Table pour les alertes de tendance
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trend_alerts(
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        actions TEXT NOT NULL,
        prevention_window_hours INTEGER,
        timestamp TEXT NOT NULL,
        metadata TEXT,
        is_read INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Table pour les scores de fragilité
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fragility_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        value REAL NOT NULL,
        level TEXT NOT NULL,
        factors TEXT NOT NULL,
        next_review_hours INTEGER NOT NULL,
        recommendations TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Table pour les recommandations actionnables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS actionable_recommendations(
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        deadline TEXT NOT NULL,
        estimated_duration_minutes INTEGER NOT NULL,
        is_critical INTEGER NOT NULL,
        success_criteria TEXT NOT NULL,
        category TEXT NOT NULL,
        priority INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // Index pour améliorer les performances (IF NOT EXISTS pour éviter erreurs)
    try {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_trend_alerts_user ON trend_alerts(user_id, timestamp DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_fragility_scores_user ON fragility_scores(user_id, timestamp DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_recommendations_user ON actionable_recommendations(user_id, completed, deadline)');
    } catch (e) {
      // Index peuvent déjà exister
      print('⚠️ Index creation skipped (may already exist): $e');
    }
  }
  
  /// Méthode publique pour s'assurer que les tables prédictives existent
  Future<void> ensurePredictiveTablesExist() async {
    final db = await database;
    await _createPredictiveTables(db);
  }
}
