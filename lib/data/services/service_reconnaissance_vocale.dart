import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service de reconnaissance vocale (Simulé)
/// Permet de déclarer l'état de l'utilisateur par la voix.
class ServiceReconnaissanceVocale {
  static final ServiceReconnaissanceVocale _instance =
      ServiceReconnaissanceVocale._internal();
  factory ServiceReconnaissanceVocale() => _instance;
  ServiceReconnaissanceVocale._internal();

  bool _isListening = false;
  final _controller = StreamController<String>.broadcast();

  bool get isListening => _isListening;
  Stream<String> get wordsStream => _controller.stream;

  /// Démarre l'écoute (Simulation)
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    debugPrint('🎤 ÉCOUTE VOCALE ACTIVÉE (Simulation)');
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    _isListening = false;
    debugPrint('🎤 ÉCOUTE VOCALE DÉSACTIVÉE');
  }

  /// Simule la détection d'un mot (Pour le test/démo)
  void simulateWord(String word) {
    if (!_isListening) return;
    debugPrint('🎤 MOT DÉTECTÉ (Simulé) : $word');
    _controller.add(word.toLowerCase());
  }

  /// Analyse si le texte contient des mots-clés d'urgence
  bool isEmergency(String text) {
    final keywords = [
      'urgence',
      'aide',
      'au secours',
      'pompier',
      'samu',
      'je ne vais pas bien',
      'mal',
      'souffle',
      'étouffe',
      'crise'
    ];
    return keywords.any((k) => text.toLowerCase().contains(k));
  }

  /// Analyse si le texte contient des mots-clés d'annulation
  bool isCancel(String text) {
    final keywords = [
      'annuler',
      'je vais bien',
      'tout va bien',
      'stop',
      'ça va',
      'fausse alerte'
    ];
    return keywords.any((k) => text.toLowerCase().contains(k));
  }

  /// Extrait l'état déclaré par l'utilisateur
  String getDeclaredState(String text) {
    if (text.toLowerCase().contains('étouffe') ||
        text.toLowerCase().contains('souffle')) {
      return 'Difficulté respiratoire déclarée';
    }
    if (text.toLowerCase().contains('mal')) {
      return 'Douleur déclarée';
    }
    if (text.toLowerCase().contains('crise')) {
      return 'Crise déclarée';
    }
    return 'État critique déclaré vocalement';
  }
}
