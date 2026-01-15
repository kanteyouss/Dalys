import 'package:flutter/foundation.dart';

/// Modèle représentant une entrée quotidienne de symptômes
/// Collectée via le chatbot pour le suivi de santé
class EntreeSymptomeQuotidien {
  final String id;
  final int? userId;
  final DateTime date;
  final List<String> symptomes; // Liste des symptômes signalés
  final String severite; // "leger", "moyen", "fort"
  final String? notesSupplementaires; // Notes supplémentaires de l'utilisateur
  final Map<String, dynamic> metadonnees; // Données extraites par NLP

  EntreeSymptomeQuotidien({
    required this.id,
    this.userId,
    required this.date,
    required this.symptomes,
    required this.severite,
    this.notesSupplementaires,
    Map<String, dynamic>? metadonnees,
  }) : metadonnees = metadonnees ?? {};

  /// Crée une nouvelle entrée avec un ID généré automatiquement
  factory EntreeSymptomeQuotidien.creer({
    int? userId,
    required List<String> symptomes,
    required String severite,
    String? notesSupplementaires,
    Map<String, dynamic>? metadonnees,
  }) {
    return EntreeSymptomeQuotidien(
      id: 'symptome_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      date: DateTime.now(),
      symptomes: symptomes,
      severite: severite,
      notesSupplementaires: notesSupplementaires,
      metadonnees: metadonnees,
    );
  }

  /// Convertit depuis JSON (base de données)
  factory EntreeSymptomeQuotidien.depuisJson(Map<String, dynamic> json) {
    return EntreeSymptomeQuotidien(
      id: json['id'] as String,
      userId: json['user_id'] as int?,
      date: DateTime.parse(json['date'] as String),
      symptomes: (json['symptomes'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      severite: json['severite'] as String,
      notesSupplementaires: json['notes_supplementaires'] as String?,
      metadonnees: json['metadonnees'] != null
          ? Map<String, dynamic>.from(json['metadonnees'] as Map)
          : {},
    );
  }

  /// Convertit vers JSON (base de données)
  Map<String, dynamic> versJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'symptomes': symptomes.join(','),
      'severite': severite,
      'notes_supplementaires': notesSupplementaires,
      'metadonnees': metadonnees,
    };
  }

  /// Convertit vers Map pour SQLite
  Map<String, dynamic> versMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'symptomes': symptomes.join(','),
      'severite': severite,
      'notes_supplementaires': notesSupplementaires,
      'metadonnees': _encoderMetadonnees(metadonnees),
    };
  }

  /// Crée depuis Map SQLite
  factory EntreeSymptomeQuotidien.depuisMap(Map<String, dynamic> map) {
    return EntreeSymptomeQuotidien(
      id: map['id'] as String,
      userId: map['user_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      symptomes: (map['symptomes'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      severite: map['severite'] as String,
      notesSupplementaires: map['notes_supplementaires'] as String?,
      metadonnees: _decoderMetadonnees(map['metadonnees'] as String?),
    );
  }

  /// Encode metadata en JSON string pour SQLite
  static String _encoderMetadonnees(Map<String, dynamic> metadonnees) {
    if (metadonnees.isEmpty) return '{}';
    try {
      return metadonnees.toString();
    } catch (e) {
      debugPrint('Erreur encodage metadonnees: $e');
      return '{}';
    }
  }

  /// Decode metadata depuis JSON string
  static Map<String, dynamic> _decoderMetadonnees(String? metadonneesStr) {
    if (metadonneesStr == null ||
        metadonneesStr.isEmpty ||
        metadonneesStr == '{}') {
      return {};
    }
    try {
      // Simple parsing pour le prototype
      return {};
    } catch (e) {
      debugPrint('Erreur décodage metadonnees: $e');
      return {};
    }
  }

  /// Copie avec modifications
  EntreeSymptomeQuotidien copierAvec({
    String? id,
    int? userId,
    DateTime? date,
    List<String>? symptomes,
    String? severite,
    String? notesSupplementaires,
    Map<String, dynamic>? metadonnees,
  }) {
    return EntreeSymptomeQuotidien(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      symptomes: symptomes ?? this.symptomes,
      severite: severite ?? this.severite,
      notesSupplementaires: notesSupplementaires ?? this.notesSupplementaires,
      metadonnees: metadonnees ?? this.metadonnees,
    );
  }

  /// Vérifie si l'entrée est d'aujourd'hui
  bool get estAujourdhui {
    final maintenant = DateTime.now();
    return date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day;
  }

  /// Nombre de symptômes signalés
  int get nombreSymptomes => symptomes.length;

  /// Vérifie si l'entrée indique des symptômes graves
  bool get aSymptomesGraves => severite == 'fort' || severite == 'grave';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntreeSymptomeQuotidien && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EntreeSymptomeQuotidien(id: $id, date: $date, symptomes: $symptomes, severite: $severite)';
  }
}
