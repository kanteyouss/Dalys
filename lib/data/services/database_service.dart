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

    return await openDatabase(
      path,
      version: 8, // Augmentation pour photo_url
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
}
