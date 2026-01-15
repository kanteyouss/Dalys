import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../data/services/emergency_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/service_reconnaissance_vocale.dart';
import '../../../data/services/service_vocal.dart';

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

  static void show(
      BuildContext context, UserModel user, String stateDescription) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyCountdownOverlay(
        user: user,
        stateDescription: stateDescription,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<EmergencyCountdownOverlay> createState() =>
      _EmergencyCountdownOverlayState();
}

class _EmergencyCountdownOverlayState extends State<EmergencyCountdownOverlay> {
  int _remainingSeconds = 20;
  final EmergencyService _emergencyService = EmergencyService();
  final ServiceReconnaissanceVocale _voiceService =
      ServiceReconnaissanceVocale();
  final ServiceVocal _vocalService = ServiceVocal();
  StreamSubscription? _voiceSubscription;

  @override
  void initState() {
    super.initState();
    _emergencyService.triggerEmergencyWithCountdown(
      widget.user,
      widget.stateDescription,
      onTick: (seconds) {
        if (mounted) {
          setState(() => _remainingSeconds = seconds);
          // Feedback sensoriel à chaque seconde
          HapticFeedback.heavyImpact();
          _vocalService
              .parler(seconds.toString()); // Optionnel: dire le chiffre
        }
      },
      onComplete: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    // Démarrer l'écoute vocale pour l'annulation
    _voiceService.startListening();
    _voiceSubscription = _voiceService.wordsStream.listen((word) {
      if (_voiceService.isCancel(word)) {
        debugPrint('🎤 ANNULATION VOCALE DÉTECTÉE');
        _cancelEmergency();
      }
    });
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
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Fond sombre pour contraste max
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
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
              const Text(
                'ALERTE CRITIQUE',
                style: TextStyle(
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
                      value: _remainingSeconds / 20,
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
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Aide en route si vous ne répondez pas.',
                style: TextStyle(
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
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'JE VAIS BIEN',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '(Annuler l\'alerte)',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Option vocale
              TextButton.icon(
                onPressed: () {
                  // Ici on pourrait forcer l'ouverture du micro pour parler
                  HapticFeedback.mediumImpact();
                },
                icon: const Icon(Icons.mic, color: Colors.blueAccent),
                label: const Text(
                  'Parler pour préciser mon état',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),
            ],
          ),
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
