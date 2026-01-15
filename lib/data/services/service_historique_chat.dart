import 'package:sqflite/sqflite.dart';
import '../models/message_chatbot.dart';
import 'database_service.dart';

/// Service pour la persistance de l'historique du chat
class ServiceHistoriqueChat {
  final DatabaseService _databaseService = DatabaseService();

  /// Sauvegarde un message dans la base de données
  Future<void> sauvegarderMessage(MessageChatbot message, int userId) async {
    final db = await _databaseService.database;
    await db.insert(
      'historique_chat',
      {
        'id': message.id,
        'user_id': userId,
        'date': message.timestamp.toIso8601String(),
        'texte': message.text,
        'est_utilisateur': message.isUser ? 1 : 0,
        'type': message.type.name,
        'reponses_rapides': message.quickReplies?.join(',') ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tout l'historique des conversations pour un utilisateur
  Future<List<MessageChatbot>> recupererHistorique(int userId) async {
    final db = await _databaseService.database;
    final resultats = await db.query(
      'historique_chat',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    return resultats.map((map) {
      final quickRepliesStr = map['reponses_rapides'] as String;
      return MessageChatbot(
        id: map['id'] as String,
        text: map['texte'] as String,
        isUser: (map['est_utilisateur'] as int) == 1,
        timestamp: DateTime.parse(map['date'] as String),
        type: MessageType.values.firstWhere(
          (e) => e.name == (map['type'] as String),
          orElse: () => MessageType.text,
        ),
        quickReplies:
            quickRepliesStr.isNotEmpty ? quickRepliesStr.split(',') : null,
      );
    }).toList();
  }

  /// Efface tout l'historique pour un utilisateur
  Future<void> effacerHistorique(int userId) async {
    final db = await _databaseService.database;
    await db.delete(
      'historique_chat',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
