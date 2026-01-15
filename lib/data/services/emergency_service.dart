import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'service_vocal.dart';
import 'service_email.dart';
import '../../core/config/medical_config.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final ServiceVocal _vocalService = ServiceVocal();
  Timer? _countdownTimer;
  bool _isEmergencyPending = false;
  StreamSubscription<Position>? _locationStreamSubscription;
  Position? _lastPosition;

  bool get isEmergencyPending => _isEmergencyPending;

  /// Déclenche le protocole d'urgence avec un compte à rebours
  void triggerEmergencyWithCountdown(UserModel user, String stateDescription,
      {Function(int)? onTick, Function()? onComplete}) {
    if (_isEmergencyPending) return;

    _isEmergencyPending = true;
    int remaining = MedicalConfig.emergencyCountdownSeconds;

    onTick?.call(remaining);

    // Pré-activation de la localisation (warm-up) pendant le compte à rebours
    _getCurrentLocation().then((pos) {
      if (pos != null) _lastPosition = pos;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      remaining--;
      onTick?.call(remaining);

      // Vérifier périodiquement si la localisation est activée
      if (remaining % 5 == 0) {
        try {
          final enabled = await Geolocator.isLocationServiceEnabled();
          if (!enabled) {
            debugPrint(
                '⚠️ Localisation désactivée. Tentative d\'ouverture des paramètres...');
            if (!Platform.isLinux) {
              await Geolocator.openLocationSettings();
            }
          }
        } catch (e) {
          if (!Platform.isLinux) {
            debugPrint(
                '⚠️ Erreur lors de la vérification de la localisation : $e');
          }
        }
      }

      if (remaining <= 0) {
        timer.cancel();
        _isEmergencyPending = false;
        await triggerEmergencyProtocol(user, stateDescription);
        onComplete?.call();
      }
    });
  }

  /// Annule l'urgence en cours
  void cancelEmergency() {
    _countdownTimer?.cancel();
    _isEmergencyPending = false;
    _stopLocationTracking();
    debugPrint('🛑 URGENCE ANNULÉE PAR L\'UTILISATEUR');
  }

  /// Déclenche le protocole d'urgence (immédiat)
  Future<void> triggerEmergencyProtocol(
      UserModel user, String stateDescription) async {
    debugPrint('🚨 PROTOCOLE D\'URGENCE DÉCLENCHÉ 🚨');

    // 1. Activation automatique de la localisation et récupération de la position
    _lastPosition = await _getCurrentLocation();

    // 2. Démarrage du suivi en temps réel
    _startLocationTracking(user);

    // 3. Annonce vocale de l'état
    await _announceStateVocally(stateDescription);

    // 4. Envoi d'alertes aux proches (Simulation)
    await _sendAlertsToRelatives(user, _lastPosition, stateDescription);
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        if (!Platform.isLinux) {
          debugPrint(
              '⚠️ Geolocator.isLocationServiceEnabled non supporté : $e');
        }
      }

      if (!serviceEnabled) {
        debugPrint('Location services are disabled or not supported.');
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (e) {
          debugPrint('⚠️ Geolocator.getLastKnownPosition non supporté : $e');
          return null;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return await Geolocator.getLastKnownPosition();
      }

      // Tentative de récupération de la position actuelle avec un timeout court
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (e) {
        debugPrint(
            'Timeout ou erreur position actuelle, fallback vers dernière connue: $e');
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  void _startLocationTracking(UserModel user) {
    try {
      _locationStreamSubscription?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Notifier tous les 10 mètres
      );

      _locationStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _lastPosition = position;
        debugPrint(
            '📍 MISE À JOUR POSITION TEMPS RÉEL : ${position.latitude}, ${position.longitude}');
        // Ici on pourrait renvoyer un SMS de mise à jour si le déplacement est significatif
      }, onError: (e) {
        debugPrint('⚠️ Erreur flux localisation : $e');
      });
    } catch (e) {
      debugPrint('⚠️ Impossible de démarrer le suivi de localisation : $e');
    }
  }

  void _stopLocationTracking() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    debugPrint('📍 ARRÊT DU SUIVI DE POSITION');
  }

  Future<void> _announceStateVocally(String description) async {
    String message =
        "Alerte d'urgence. L'état de l'utilisateur est : $description.";
    await _vocalService.parler(message);
  }

  Future<void> _sendAlertsToRelatives(
      UserModel user, Position? position, String state) async {
    if (user.emergencyContactPhone == null &&
        user.emergencyContactEmail == null) {
      debugPrint('Aucun contact d\'urgence (téléphone ou email) configuré.');
      return;
    }

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    String googleMapsUrl = position != null
        ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
        : '';

    String locationInfo = position != null
        ? 'Position : $googleMapsUrl (Suivi en temps réel activé)'
        : 'Position inconnue (Recherche en cours...)';

    String plainMessage =
        'URGENCE DALYS : ${user.prenom} ${user.nom} est dans un état critique ($state).\n'
        'Heure : $timeStr\n'
        'Téléphone : ${user.telephone ?? "Non renseigné"}\n'
        '$locationInfo';

    String htmlMessage = '''
      <div style="font-family: sans-serif; border: 2px solid #e53935; padding: 20px; border-radius: 10px;">
        <h2 style="color: #e53935; margin-top: 0;">🚨 ALERTE D'URGENCE DALYS</h2>
        <p><strong>${user.prenom} ${user.nom}</strong> a besoin d'aide immédiatement.</p>
        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
        <p><strong>État déclaré :</strong> <span style="color: #e53935; font-weight: bold;">$state</span></p>
        <p><strong>Heure de l'alerte :</strong> $timeStr</p>
        <p><strong>Téléphone :</strong> <a href="tel:${user.telephone}">${user.telephone ?? "Non renseigné"}</a></p>
        <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin-top: 20px;">
          <p style="margin-top: 0;"><strong>Localisation :</strong></p>
          ${position != null ? '<a href="$googleMapsUrl" style="display: inline-block; background: #1a73e8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-weight: bold;">VOIR SUR GOOGLE MAPS</a>' : '<p style="color: #757575;">Position en cours de récupération...</p>'}
          <p style="font-size: 12px; color: #757575; margin-bottom: 0; margin-top: 10px;">Le suivi en temps réel est activé sur l'appareil.</p>
        </div>
        <p style="font-size: 12px; color: #9e9e9e; margin-top: 30px;">Ceci est une alerte automatique générée par l'application DALYS.</p>
      </div>
    ''';

    if (user.emergencyContactPhone != null) {
      debugPrint(
          '📱 ENVOI SMS à ${user.emergencyContactPhone} : $plainMessage');
    }

    if (user.emergencyContactEmail != null) {
      debugPrint(
          '📧 TENTATIVE D\'ENVOI EMAIL ENRICHI à ${user.emergencyContactEmail}...');
      EmailService().sendEmergencyEmail(
        recipientEmail: user.emergencyContactEmail!,
        subject: '🚨 URGENCE DALYS : ${user.prenom} ${user.nom}',
        body: plainMessage,
        html: htmlMessage,
      );
    }
  }
}
