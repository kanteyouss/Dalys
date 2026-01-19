import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../data/services/emergency_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/service_reconnaissance_vocale.dart';
import '../../../data/services/service_vocal.dart';
import '../../../data/models/modele_alerte.dart';
import 'package:provider/provider.dart';
import '../../health_monitoring/controllers/health_controller.dart';

class EmergencyCountdownOverlay extends StatefulWidget {
  final UserModel user;
  final String stateDescription;
  final VoidCallback onCancel;

  const EmergencyCountdownOverlay({
    super.key,
    required this.user,
    required this.stateDescription,
    required this.onCancel,
  });

  static bool isShowing = false;

  static void show(
      BuildContext context, UserModel user, String stateDescription) {
    // Empêcher l'empilement des overlays
    if (isShowing) {
      debugPrint('⚠️ Overlay urgence déjà affiché - Ignoré');
      return;
    }

    // Vérifier que le contexte a bien un Navigator
    try {
      Navigator.of(context);
    } catch (e) {
      debugPrint(
          '❌ Erreur: Context sans Navigator actif pour EmergencyCountdownOverlay: $e');
      return;
    }

    isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyCountdownOverlay(
        user: user,
        stateDescription: stateDescription,
        onCancel: () => Navigator.of(context).pop(),
      ),
    ).then((_) => isShowing = false); // Réinitialiser le flag à la fermeture
  }

  @override
  State<EmergencyCountdownOverlay> createState() =>
      _EmergencyCountdownOverlayState();
}

class _EmergencyCountdownOverlayState extends State<EmergencyCountdownOverlay> {
  int _remainingSeconds = 10;
  final EmergencyService _emergencyService = EmergencyService();
  final ServiceReconnaissanceVocale _voiceService =
      ServiceReconnaissanceVocale();
  final ServiceVocal _vocalService = ServiceVocal();
  StreamSubscription? _voiceSubscription;

  @override
  void initState() {
    super.initState();

    // ✅ INITIALISER et DÉMARRER l'écoute vocale AVANT le compte à rebours
    _initializeVoiceRecognition();

    _emergencyService.triggerEmergencyWithCountdown(
      widget.user,
      widget.stateDescription,
      recentHistory: context.read<HealthController>().historicalData,
      onTick: (seconds) {
        if (mounted) {
          setState(() => _remainingSeconds = seconds);
          // Feedback sensoriel à chaque seconde
          HapticFeedback.heavyImpact();

          // Rappel vocal à mi-parcours
          if (seconds == 5) {
            _vocalService.parler(
              "Dites 'je vais bien' pour annuler l'alerte",
              niveau: NiveauNotification.urgence,
            );
          }
        }
      },
      onComplete: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  /// Initialise la reconnaissance vocale et configure l'écoute
  Future<void> _initializeVoiceRecognition() async {
    try {
      // Initialiser le service de reconnaissance
      final initialized = await _voiceService.initialize();
      if (!initialized) {
        debugPrint('⚠️ Reconnaissance vocale non disponible');
        // Continuer quand même, l'utilisateur peut toujours appuyer sur le bouton
        return;
      }

      // Démarrer l'écoute vocale
      await _voiceService.startListening();

      // Annonce vocale initiale
      await _vocalService.parler(
        "Alerte d'urgence déclenchée. Dites 'je vais bien' pour annuler.",
        niveau: NiveauNotification.urgence,
      );

      // Écouter les mots reconnus
      _voiceSubscription = _voiceService.wordsStream.listen((text) {
        debugPrint('🎤 Reconnaissance: "$text"');

        if (_voiceService.isCancel(text)) {
          debugPrint('✅ ANNULATION VOCALE DÉTECTÉE: "$text"');

          // Confirmation vocale
          _vocalService.parler(
            "Annulation confirmée. Vous allez bien.",
            niveau: NiveauNotification.alerte,
          );

          // Annuler l'urgence
          _cancelEmergency();
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur initialisation reconnaissance vocale: $e');
      // L'utilisateur peut toujours utiliser le bouton tactile
    }
  }

  void _cancelEmergency() {
    _emergencyService.cancelEmergency();
    widget.onCancel();
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF1A1A1A), // Fond sombre pour contraste max
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPulsingIcon(),
                  const SizedBox(height: 20),
                  Text(
                    _remainingSeconds > 0
                        ? 'ALERTE CRITIQUE'
                        : 'ALERTE ENVOYÉE',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Un état critique a été détecté :\n"${widget.stateDescription}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Compteur circulaire haute visibilité
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _remainingSeconds / 10,
                          strokeWidth: 12,
                          color: Colors.red,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_remainingSeconds',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'secondes',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    _remainingSeconds > 0
                        ? 'Aide en route si vous ne répondez pas.'
                        : 'Vos proches ont été prévenus.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton JE VAIS BIEN (Action Primaire)
                  ElevatedButton(
                    onPressed: _cancelEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _remainingSeconds > 0 ? 'JE VAIS BIEN' : 'FERMER',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _remainingSeconds > 0
                              ? '(Annuler l\'alerte)'
                              : '(Alerte envoyée)',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Option vocale avec indication claire
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _voiceService.isListening ? Icons.mic : Icons.mic_off,
                          color: _voiceService.isListening
                              ? Colors.green
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _voiceService.isListening
                                ? '🎤 Dites "je vais bien" pour annuler'
                                : '🎤 Microphone non disponible - Utilisez le bouton',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _voiceService.isListening
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _cancelEmergency,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: const Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 80),
        );
      },
      onEnd: () {
        // Simple hack pour boucler l'animation sans controller complexe ici
      },
    );
  }
}
