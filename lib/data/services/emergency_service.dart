import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'service_vocal.dart';
import 'service_email.dart';
import '../../core/config/medical_config.dart';
import '../models/modele_alerte.dart';
import '../models/health_data.dart';

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
      {Function(int)? onTick,
      Function()? onComplete,
      List<HealthData>? recentHistory,
      String? intendedDestination}) {
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
        // Déclencher le protocole en arrière-plan pour ne pas bloquer l'UI
        triggerEmergencyProtocol(user, stateDescription,
            recentHistory: recentHistory,
            intendedDestination: intendedDestination);
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
  Future<void> triggerEmergencyProtocol(UserModel user, String stateDescription,
      {List<HealthData>? recentHistory, String? intendedDestination}) async {
    debugPrint('🚨 PROTOCOLE D\'URGENCE DÉCLENCHÉ 🚨');

    // 1. Activation automatique de la localisation et récupération de la position
    _lastPosition = await _getCurrentLocation();

    // 2. Démarrage du suivi en temps réel
    _startLocationTracking(user);

    // 3. Annonce vocale de l'état
    await _announceStateVocally(stateDescription);

    // 4. Envoi d'alertes aux contacts (Médecin, Hôpital, Proche)
    await _sendAlertsToContacts(user, _lastPosition, stateDescription,
        recentHistory: recentHistory, intendedDestination: intendedDestination);
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
    await _vocalService.parler(message, niveau: NiveauNotification.urgence);
  }

  Future<void> _sendAlertsToContacts(
      UserModel user, Position? position, String state,
      {List<HealthData>? recentHistory, String? intendedDestination}) async {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    String googleMapsUrl = position != null
        ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
        : '';

    // 1. Envoi au Proche (Rassurant, Actions simples)
    if (user.emergencyContactEmail != null) {
      debugPrint('📧 Envoi email PROCHE à ${user.emergencyContactEmail}...');
      final htmlBody =
          _generateRelativeEmail(user, position, state, timeStr, googleMapsUrl);
      final plainBody =
          "URGENCE : ${user.prenom} a besoin d'aide. État : $state. Tel : ${user.telephone}";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.emergencyContactEmail!,
        subject: '🚨 URGENCE : ${user.prenom} ${user.nom} a besoin d\'aide',
        body: plainBody,
        html: htmlBody,
      );
    }

    // 2. Envoi au Médecin (Données médicales, État clinique)
    if (user.doctorEmail != null) {
      debugPrint('📧 Envoi email MÉDECIN à ${user.doctorEmail}...');
      final htmlBody = _generateDoctorEmail(
          user, position, state, timeStr, googleMapsUrl, recentHistory);
      final plainBody =
          "ALERTE MÉDICALE : Patient ${user.nom} ${user.prenom}. État : $state.";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.doctorEmail!,
        subject: 'URGENCE MÉDICALE : Patient ${user.nom} ${user.prenom}',
        body: plainBody,
        html: htmlBody,
      );
    }

    // 3. Envoi à l'Hôpital (Localisation précise, Identité)
    if (user.hospitalEmail != null) {
      debugPrint('📧 Envoi email HÔPITAL à ${user.hospitalEmail}...');
      final htmlBody = _generateHospitalEmail(user, position, state, timeStr,
          googleMapsUrl, intendedDestination, recentHistory);
      final plainBody =
          "ADMISSION URGENCE : ${user.nom} ${user.prenom}. Localisation : $googleMapsUrl";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.hospitalEmail!,
        subject: 'ADMISSION URGENCE : ${user.nom} ${user.prenom}',
        body: plainBody,
        html: htmlBody,
      );
    }

    // SMS au proche (toujours envoyé si numéro dispo)
    if (user.emergencyContactPhone != null) {
      debugPrint(
          '📱 SMS simulé vers ${user.emergencyContactPhone} : URGENCE DALYS - ${user.prenom} est en danger ($state).');
    }
  }

  String _generateRelativeEmail(UserModel user, Position? position,
      String state, String timeStr, String mapUrl) {
    return '''
      <div style="font-family: sans-serif; border: 2px solid #e53935; padding: 20px; border-radius: 10px;">
        <h2 style="color: #e53935; margin-top: 0;">🚨 ALERTE PROCHE</h2>
        <p><strong>${user.prenom}</strong> a déclenché une alerte d'urgence.</p>
        <div style="background: #ffebee; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p style="margin:0;"><strong>Ce qu'il se passe :</strong> $state</p>
        </div>
        <p><strong>Heure :</strong> $timeStr</p>
        <p><strong>Son téléphone :</strong> <a href="tel:${user.telephone}">${user.telephone ?? "Non renseigné"}</a></p>
        
        <div style="margin-top: 20px;">
          ${position != null ? '<a href="$mapUrl" style="background: #d32f2f; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">VOIR SA POSITION</a>' : '<p>Localisation en cours...</p>'}
        </div>
        <p style="color: #757575; font-size: 12px; margin-top: 30px;">Envoyé via DALYS - Prévention Respiratoire</p>
      </div>
    ''';
  }

  String _generateDoctorEmail(UserModel user, Position? position, String state,
      String timeStr, String mapUrl, List<HealthData>? history) {
    String historyTable = '';
    if (history != null && history.isNotEmpty) {
      final recent = history.take(5).toList();
      historyTable = '''
        <h3>Dernières Constantes (24h)</h3>
        <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
          <tr style="background: #f5f5f5;">
            <th style="border: 1px solid #ddd; padding: 8px;">Heure</th>
            <th style="border: 1px solid #ddd; padding: 8px;">SpO2</th>
            <th style="border: 1px solid #ddd; padding: 8px;">BPM</th>
            <th style="border: 1px solid #ddd; padding: 8px;">PEF</th>
          </tr>
          ${recent.map((d) => '''
            <tr>
              <td style="border: 1px solid #ddd; padding: 8px;">${d.date.hour}:${d.date.minute.toString().padLeft(2, '0')}</td>
              <td style="border: 1px solid #ddd; padding: 8px; color: ${d.isSpo2Normal ? 'black' : 'red'};">${d.spo2}%</td>
              <td style="border: 1px solid #ddd; padding: 8px; color: ${d.isBreathingRateNormal ? 'black' : 'red'};">${d.breathingRate}</td>
              <td style="border: 1px solid #ddd; padding: 8px; color: ${d.isPefNormal ? 'black' : 'red'};">${d.pef.toInt()}</td>
            </tr>
          ''').join('')}
        </table>
      ''';
    }

    return '''
      <div style="font-family: sans-serif; border: 1px solid #1976d2; padding: 20px; border-radius: 5px;">
        <h2 style="color: #1976d2; margin-top: 0;">DOSSIER PATIENT : ALERTE MÉDICALE</h2>
        <p><strong>Patient :</strong> ${user.nom.toUpperCase()} ${user.prenom}</p>
        <hr>
        <h3>État Clinique Déclaré</h3>
        <p style="font-size: 16px; background: #e3f2fd; padding: 10px;">$state</p>
        
        $historyTable

        <h3>Données Contextuelles</h3>
        <ul>
          <li><strong>Heure de l'incident :</strong> $timeStr</li>
          <li><strong>Localisation :</strong> ${position != null ? 'Disponible (voir carte)' : 'Non disponible'}</li>
        </ul>
        
        <div style="margin-top: 20px;">
          ${position != null ? '<a href="$mapUrl" style="color: #1976d2; text-decoration: underline;">Voir la localisation du patient</a>' : ''}
        </div>
      </div>
    ''';
  }

  String _generateHospitalEmail(
      UserModel user,
      Position? position,
      String state,
      String timeStr,
      String mapUrl,
      String? destination,
      List<HealthData>? history) {
    String vitalsSummary = '';
    if (history != null && history.isNotEmpty) {
      final last = history.last;
      vitalsSummary = '''
        <div style="border: 1px solid #000; padding: 10px; margin: 10px 0;">
          <p style="margin: 0;"><strong>CONSTANTES ACTUELLES :</strong> SpO2: ${last.spo2}% | BPM: ${last.breathingRate} | PEF: ${last.pef.toInt()}</p>
        </div>
      ''';
    }

    return '''
      <div style="font-family: monospace; border: 3px solid #000; padding: 20px;">
        <h1 style="margin: 0; background: #000; color: #fff; padding: 5px;">URGENCE / ADMISSION</h1>
        
        <div style="display: flex; justify-content: space-between; margin-top: 20px;">
          <div>
            <p><strong>NOM :</strong> ${user.nom.toUpperCase()}</p>
            <p><strong>PRÉNOM :</strong> ${user.prenom.toUpperCase()}</p>
          </div>
          <div style="text-align: right;">
            <p><strong>HEURE :</strong> $timeStr</p>
            <p><strong>PRIORITÉ :</strong> HAUTE</p>
          </div>
        </div>

        ${destination != null ? '<div style="background: #ffeb3b; padding: 10px; margin: 10px 0; font-weight: bold;">DESTINATION PRÉVUE : $destination</div>' : ''}

        <div style="border: 1px solid #000; padding: 10px; margin: 20px 0;">
          <p style="margin: 0;"><strong>MOTIF :</strong> $state</p>
        </div>

        $vitalsSummary

        <p><strong>LOCALISATION ACTUELLE :</strong></p>
        ${position != null ? '<a href="$mapUrl" style="font-size: 18px; font-weight: bold;">OUVRIR LA CARTE D\'INTERVENTION</a>' : 'NON DISPONIBLE'}
        
        <p style="margin-top: 20px;"><strong>CONTACT :</strong> ${user.telephone ?? "N/A"}</p>
      </div>
    ''';
  }
}
