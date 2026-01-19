import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service de reconnaissance vocale avec speech_to_text
/// Permet de détecter les commandes vocales d'urgence et d'annulation
class ServiceReconnaissanceVocale {
  static final ServiceReconnaissanceVocale _instance =
      ServiceReconnaissanceVocale._internal();
  factory ServiceReconnaissanceVocale() => _instance;
  ServiceReconnaissanceVocale._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  final _controller = StreamController<String>.broadcast();

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  Stream<String> get wordsStream => _controller.stream;

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Demander la permission du microphone
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        debugPrint('⚠️ Permission microphone refusée');
        return false;
      }

      // Initialiser speech_to_text
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('❌ Erreur reconnaissance vocale: $error'),
        onStatus: (status) => debugPrint('🎤 Statut: $status'),
      );

      if (_isInitialized) {
        debugPrint('✅ Service de reconnaissance vocale initialisé');
      } else {
        debugPrint('❌ Échec initialisation reconnaissance vocale');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Erreur initialisation reconnaissance vocale: $e');
      return false;
    }
  }

  /// Démarre l'écoute vocale réelle
  Future<void> startListening() async {
    if (_isListening) return;

    // S'assurer que le service est initialisé
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('⚠️ Impossible de démarrer l\'écoute (non initialisé)');
        return;
      }
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final text = result.recognizedWords.toLowerCase();
            debugPrint('🎤 DÉTECTÉ: "$text"');
            _controller.add(text);

            // Redémarrer l'écoute si elle s'arrête automatiquement
            if (result.finalResult && _isListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_isListening) {
                  _speech.listen(
                    onResult: (result) {
                      if (result.recognizedWords.isNotEmpty) {
                        final text = result.recognizedWords.toLowerCase();
                        debugPrint('🎤 DÉTECTÉ: "$text"');
                        _controller.add(text);
                      }
                    },
                    listenFor: const Duration(seconds: 30),
                    pauseFor: const Duration(seconds: 5),
                    partialResults: true,
                    listenMode: stt.ListenMode.confirmation,
                    listenOptions: stt.SpeechListenOptions(
                      cancelOnError: false,
                    ),
                  );
                }
              });
            }
          }
        },
        listenFor: const Duration(seconds: 30), // Durée d'écoute continue
        pauseFor: const Duration(seconds: 5), // Pause avant arrêt auto
        partialResults: true, // Résultats partiels pour réactivité
        listenMode: stt.ListenMode.confirmation,
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
        ),
      );
      debugPrint('🎤 ÉCOUTE VOCALE ACTIVÉE (Réelle)');
    } catch (e) {
      debugPrint('❌ Erreur démarrage écoute: $e');
      _isListening = false;
    }
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('🎤 ÉCOUTE VOCALE DÉSACTIVÉE');
    } catch (e) {
      debugPrint('❌ Erreur arrêt écoute: $e');
      _isListening = false;
    }
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
  /// Utilise une détection TRÈS permissive pour maximiser les chances d'annulation
  bool isCancel(String text) {
    final textLower = text.toLowerCase();
    
    // Mots-clés d'annulation directs
    final directKeywords = [
      'je vais bien',
      'tout va bien',
      'ça va',
      'je me sens bien',
      'je suis bien',
      'fausse alerte',
      'annuler',
      'annule',
      'stop',
      'arrêter',
      'arrête',
      'cancel',
    ];

    // Détection directe
    if (directKeywords.any((k) => textLower.contains(k))) {
      debugPrint('✅ ANNULATION DÉTECTÉE (direct): "$text"');
      return true;
    }

    // Détection par composants ("bien" seul suffit dans contexte d'urgence)
    final componentKeywords = ['bien', 'ok', 'okay'];
    if (componentKeywords.any((k) => textLower.contains(k))) {
      debugPrint('✅ ANNULATION DÉTECTÉE (composant): "$text"');
      return true;
    }

    return false;
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

  /// Nettoie les ressources
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
  }
}
