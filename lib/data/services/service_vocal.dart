import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Service gérant la reconnaissance vocale (STT) et la synthèse vocale (TTS)
class ServiceVocal {
  static final ServiceVocal _instance = ServiceVocal._internal();
  factory ServiceVocal() => _instance;
  ServiceVocal._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSttInitialized = false;
  bool _isTtsInitialized = false;

  // Callbacks
  Function(String)? onStatus;
  Function(String)? onError;

  /// Initialise les services vocaux
  Future<void> initialiser() async {
    await _initTts();
    await _initStt();
  }

  Future<void> _initTts() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        debugPrint("TTS non supporté sur Linux, utilisation du mock.");
        _isTtsInitialized = true;
        return;
      }

      if (!_isTtsInitialized) {
        await _flutterTts.setLanguage("fr-FR");
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        _isTtsInitialized = true;
      }
    } catch (e) {
      debugPrint("Erreur init TTS: $e");
    }
  }

  Future<void> _initStt() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.linux) {
        debugPrint("STT non supporté sur Linux, utilisation du mock.");
        _isSttInitialized = true; // Mock initialization
        return;
      }
      
      if (!_isSttInitialized) {
        _isSttInitialized = await _speechToText.initialize(
          onStatus: (status) => onStatus?.call(status),
          onError: (error) => onError?.call(error.errorMsg),
        );
      }
    } catch (e) {
      debugPrint("Erreur init STT: $e");
    }
  }

  /// Commence l'écoute
  Future<void> ecouter({
    required Function(String) onResult,
  }) async {
    if (!_isSttInitialized) await _initStt();

    if (defaultTargetPlatform == TargetPlatform.linux) {
      // Mock listening behavior for Linux
      onStatus?.call('listening');
      await Future.delayed(const Duration(seconds: 2));
      onResult("Ceci est une simulation vocale sur Linux");
      onStatus?.call('done');
      return;
    }

    if (_isSttInitialized) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: "fr_FR",
      );
    }
  }

  /// Arrête l'écoute
  Future<void> arreterEcoute() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    
    if (_isSttInitialized) {
      await _speechToText.stop();
    }
  }

  /// Parle (Synthèse vocale)
  Future<void> parler(String texte) async {
    if (!_isTtsInitialized) await _initTts();

    if (defaultTargetPlatform == TargetPlatform.linux) {
      debugPrint("[MOCK TTS] Robot dit : $texte");
      return;
    }

    if (texte.isNotEmpty) {
      await _flutterTts.speak(texte);
    }
  }

  /// Arrête de parler
  Future<void> arreterParole() async {
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    await _flutterTts.stop();
  }

  bool get estEnTrainDecouter => _speechToText.isListening;
}
