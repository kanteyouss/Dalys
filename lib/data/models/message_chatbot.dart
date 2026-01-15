import 'package:flutter/foundation.dart';

/// Types de messages dans le chatbot
enum MessageType {
  text,
  quickReply,
  suggestion,
  healthCard,
  diagnosticCard,
}

/// Modèle représentant un message dans le chatbot
class MessageChatbot {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<String>? quickReplies; // Options de réponse rapide
  final dynamic healthData; // Données de santé pour les cartes visuelles
  final Map<String, dynamic>? diagnosticData; // Données pour la carte de diagnostic

  MessageChatbot({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.quickReplies,
    this.healthData,
    this.diagnosticData,
  });

  /// Crée un message utilisateur
  factory MessageChatbot.user(String text) {
    return MessageChatbot(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
  }

  /// Crée un message assistant
  factory MessageChatbot.assistant(String text, {List<String>? quickReplies}) {
    return MessageChatbot(
      id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: quickReplies != null ? MessageType.quickReply : MessageType.text,
      quickReplies: quickReplies,
    );
  }

  /// Crée un message de suggestion
  factory MessageChatbot.suggestion(String text) {
    return MessageChatbot(
      id: 'suggestion_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.suggestion,
    );
  }

  /// Crée un message avec une carte de santé
  factory MessageChatbot.healthCard(dynamic data, {String text = 'Voici vos données de santé :'}) {
    return MessageChatbot(
      id: 'health_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.healthCard,
      healthData: data,
    );
  }

  /// Crée un message avec une carte de diagnostic
  factory MessageChatbot.diagnosticCard({
    required String riskLevel, // 'low', 'medium', 'high'
    required String summary,
    required List<String> recommendations,
    String text = 'Voici l\'analyse de vos symptômes :',
  }) {
    return MessageChatbot(
      id: 'diag_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.diagnosticCard,
      diagnosticData: {
        'riskLevel': riskLevel,
        'summary': summary,
        'recommendations': recommendations,
      },
    );
  }

  /// Copie avec modifications
  MessageChatbot copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    List<String>? quickReplies,
    dynamic healthData,
    Map<String, dynamic>? diagnosticData,
  }) {
    return MessageChatbot(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      quickReplies: quickReplies ?? this.quickReplies,
      healthData: healthData ?? this.healthData,
      diagnosticData: diagnosticData ?? this.diagnosticData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageChatbot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageChatbot(id: $id, text: $text, isUser: $isUser, timestamp: $timestamp, type: $type)';
  }
}
