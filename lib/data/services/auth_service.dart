import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _dbService = DatabaseService();
  UserModel? _currentUser;
  static const String _userKey = 'logged_user_id';

  UserModel? get currentUser => _currentUser;

  // Hachage du mot de passe
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Inscription
  Future<bool> register(UserModel user) async {
    try {
      final db = await _dbService.database;

      // Vérifier si l'email existe déjà
      final List<Map<String, dynamic>> existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [user.email],
      );

      if (existing.isNotEmpty) {
        return false; // Email déjà utilisé
      }

      // Hacher le mot de passe avant stockage
      final hashedUser = user.copyWith(password: _hashPassword(user.password));

      await db.insert('users', hashedUser.toMap());

      // Auto-login après inscription
      return await login(user.email, user.password);
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    try {
      final db = await _dbService.database;
      final hashedPassword = _hashPassword(password);

      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (results.isNotEmpty) {
        _currentUser = UserModel.fromMap(results.first);

        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userKey, _currentUser!.id!);

        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      return false;
    }
  }

  // Mise à jour du profil
  Future<bool> updateProfile(UserModel user) async {
    try {
      final db = await _dbService.database;

      // Si le mot de passe est modifié, il faut le hacher
      // Note: Dans cette implémentation simple, on suppose que si le mot de passe
      // passé est différent de celui stocké (qui est haché), c'est un nouveau mot de passe en clair.
      // Une meilleure approche serait d'avoir un champ séparé ou une méthode dédiée.
      UserModel userToUpdate = user;
      if (_currentUser != null && user.password != _currentUser!.password) {
        userToUpdate = user.copyWith(password: _hashPassword(user.password));
      }

      await db.update(
        'users',
        userToUpdate.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      _currentUser = userToUpdate;
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Restaurer la session au démarrage
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_userKey)) return false;

      final userId = prefs.getInt(_userKey);
      if (userId == null) return false;

      final db = await _dbService.database;
      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (results.isNotEmpty) {
        _currentUser = UserModel.fromMap(results.first);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de l\'auto-login: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
