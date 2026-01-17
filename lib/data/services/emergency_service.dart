import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Stream pour notifier les autres composants (ex: ControleurAlertes) d'une urgence
  final _onEmergencyTriggered = StreamController<String>.broadcast();
  Stream<String> get onEmergency => _onEmergencyTriggered.stream;

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
      {List<HealthData>? recentHistory,
      String? intendedDestination,
      bool isAutomatic = false}) async {
    debugPrint('🚨 PROTOCOLE D\'URGENCE DÉCLENCHÉ 🚨');
    debugPrint(isAutomatic ? '🤖 Type: AUTOMATIQUE' : '👤 Type: MANUEL');

    // 1. Activation automatique de la localisation et récupération de la position
    // Essayer plusieurs fois pour augmenter les chances d'obtenir la position
    _lastPosition = await _getCurrentLocation();
    if (_lastPosition == null) {
      debugPrint(
          '⚠️ Première tentative de localisation échouée, nouvelle tentative...');
      await Future.delayed(const Duration(seconds: 2));
      _lastPosition = await _getCurrentLocation();
    }

    // 2. Démarrage du suivi en temps réel
    _startLocationTracking(user);

    // 3. Annonce vocale de l'état
    await _announceStateVocally(stateDescription);

    // 4. Envoi d'alertes aux contacts (Médecin, Hôpital, Proche)
    await _sendAlertsToContacts(user, _lastPosition, stateDescription,
        recentHistory: recentHistory,
        intendedDestination: intendedDestination,
        isAutomatic: isAutomatic);

    // 5. Notifier les abonnés internes (ex: Historique des notifications)
    _onEmergencyTriggered.add(stateDescription);
  }

  Future<Position?> _getCurrentLocation() async {
    if (Platform.isLinux) {
      return Position(
        latitude: 5.36,
        longitude: -4.008,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 10.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    try {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        debugPrint('⚠️ Erreur vérification service localisation: $e');
        // Sur certaines plateformes, on continue quand même pour essayer d'obtenir la position
        serviceEnabled = true;
      }

      if (!serviceEnabled) {
        debugPrint(
            'ℹ️ Services de localisation désactivés, tentative de récupération de la dernière position connue...');
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (e) {
          debugPrint(
              '⚠️ Impossible de récupérer la dernière position connue: $e');
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
      if (e.toString().contains('MissingPluginException')) {
        debugPrint(
            'ℹ️ Suivi de localisation non supporté sur cette plateforme (Linux)');
      } else {
        debugPrint('⚠️ Impossible de démarrer le suivi de localisation : $e');
      }
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
      {List<HealthData>? recentHistory,
      String? intendedDestination,
      bool isAutomatic = false}) async {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    String googleMapsUrl = position != null
        ? 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}'
        : '';

    final alertType =
        isAutomatic ? '🤖 ALERTE AUTOMATIQUE' : '👤 ALERTE MANUELLE';
    final alertTypeShort = isAutomatic ? 'Auto' : 'Manuel';

    // 1. Envoi au Proche (Rassurant, Actions simples)
    if (user.emergencyContactEmail != null &&
        user.emergencyContactEmail!.isNotEmpty) {
      debugPrint(
          '📧 Préparation email PROCHE à ${user.emergencyContactEmail}...');
      final htmlBody = _generateRelativeEmail(
          user, position, state, timeStr, googleMapsUrl, alertType);
      final plainBody =
          "[$alertTypeShort] URGENCE : ${user.prenom} a besoin d'aide. État : $state. Tel : ${user.telephone}";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.emergencyContactEmail!,
        subject:
            '[$alertTypeShort] 🚨 URGENCE : ${user.prenom} ${user.nom} a besoin d\'aide',
        body: plainBody,
        html: htmlBody,
      );
    } else {
      debugPrint('⚠️ Pas d\'email de contact d\'urgence configuré');
    }

    // 2. Envoi au Médecin (Données médicales, État clinique)
    if (user.doctorEmail != null && user.doctorEmail!.isNotEmpty) {
      debugPrint('📧 Préparation email MÉDECIN à ${user.doctorEmail}...');
      final htmlBody = _generateDoctorEmail(user, position, state, timeStr,
          googleMapsUrl, alertType, recentHistory);
      final plainBody =
          "[$alertTypeShort] ALERTE MÉDICALE : Patient ${user.nom} ${user.prenom}. État : $state.";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.doctorEmail!,
        subject:
            '[$alertTypeShort] URGENCE MÉDICALE : Patient ${user.nom} ${user.prenom}',
        body: plainBody,
        html: htmlBody,
      );
    } else {
      debugPrint('⚠️ Pas d\'email de médecin configuré');
    }

    // 3. Envoi à l'Hôpital (Localisation précise, Identité)
    if (user.hospitalEmail != null && user.hospitalEmail!.isNotEmpty) {
      debugPrint('📧 Préparation email HÔPITAL à ${user.hospitalEmail}...');
      final htmlBody = _generateHospitalEmail(user, position, state, timeStr,
          googleMapsUrl, alertType, intendedDestination, recentHistory);
      final plainBody =
          "[$alertTypeShort] ADMISSION URGENCE : ${user.nom} ${user.prenom}. Localisation : $googleMapsUrl";

      await EmailService().sendEmergencyEmail(
        recipientEmail: user.hospitalEmail!,
        subject:
            '[$alertTypeShort] ADMISSION URGENCE : ${user.nom} ${user.prenom}',
        body: plainBody,
        html: htmlBody,
      );
    } else {
      debugPrint('⚠️ Pas d\'email d\'hôpital configuré');
    }

    // SMS au proche (toujours envoyé si numéro dispo)
    if (user.emergencyContactPhone != null) {
      final message = "URGENCE DALYS - ${user.prenom} est en danger ($state).";

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        debugPrint(
            '🖥️ SMS (Simulation Desktop) vers ${user.emergencyContactPhone} : $message');
      } else {
        try {
          // Sur mobile, cela ouvre l'application SMS par défaut avec le message pré-rempli
          final Uri smsUri = Uri(
            scheme: 'sms',
            path: user.emergencyContactPhone!,
            queryParameters: {'body': message},
          );

          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
            debugPrint('📱 SMS app opened successfully');
          } else {
            debugPrint('❌ Cannot launch SMS app');
          }
        } catch (e) {
          debugPrint('❌ Exception SMS : $e');
        }
      }
    }
  }

  String _generateRelativeEmail(UserModel user, Position? position,
      String state, String timeStr, String mapUrl, String alertType) {
    return '''
      <div style="font-family: sans-serif; border: 2px solid #e53935; padding: 20px; border-radius: 10px;">
        <h2 style="color: #e53935; margin-top: 0;">🚨 ALERTE PROCHE</h2>
        <div style="background: #fff3cd; padding: 10px; border-radius: 5px; border-left: 4px solid #ff9800; margin-bottom: 15px;">
          <strong>$alertType</strong>
        </div>
        <p><strong>${user.prenom}</strong> a déclenché une alerte d'urgence.</p>
        <div style="background: #ffebee; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p style="margin:0;"><strong>Ce qu'il se passe :</strong> $state</p>
        </div>
        <p><strong>Heure :</strong> $timeStr</p>
        <p><strong>Son téléphone :</strong> <a href="tel:${user.telephone}">${user.telephone ?? "Non renseigné"}</a></p>
        
        <div style="margin-top: 20px;">
          ${position != null ? '<a href="$mapUrl" style="background: #d32f2f; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">VOIR SA POSITION</a><p style="margin-top: 10px; font-size: 12px; color: #666;">GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}</p>' : '<p style="color: #ff9800; font-weight: bold;">⚠️ Localisation GPS non disponible</p><p style="font-size: 12px; color: #666;">Le service de localisation n\'a pas pu obtenir la position</p>'}
        </div>
        <p style="color: #757575; font-size: 12px; margin-top: 30px;">Envoyé via DALYS - Prévention Respiratoire</p>
      </div>
    ''';
  }

  String _generateDoctorEmail(
      UserModel user,
      Position? position,
      String state,
      String timeStr,
      String mapUrl,
      String alertType,
      List<HealthData>? recentHistory) {
    String historyTable = '';
    if (recentHistory != null && recentHistory.isNotEmpty) {
      final recent = recentHistory.take(5).toList();
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
        <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; border-left: 4px solid #1976d2; margin-bottom: 15px;">
          <strong>$alertType</strong>
        </div>
        <p><strong>Patient :</strong> ${user.nom.toUpperCase()} ${user.prenom}</p>
        <hr>
        <h3>État Clinique Déclaré</h3>
        <p style="font-size: 16px; background: #e3f2fd; padding: 10px;">$state</p>
        
        $historyTable

        <h3>Données Contextuelles</h3>
        <ul>
          <li><strong>Heure de l'incident :</strong> $timeStr</li>
          <li><strong>Localisation :</strong> ${position != null ? 'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}' : '⚠️ Non disponible'}</li>
        </ul>
        
        <div style="margin-top: 20px;">
          ${position != null ? '<a href="$mapUrl" style="color: #1976d2; text-decoration: underline; font-weight: bold;">📍 Voir la localisation du patient sur Google Maps</a>' : '<p style="color: #ff9800;">⚠️ Service de localisation indisponible</p>'}
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
      String alertType,
      String? intendedDestination,
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
        <div style="background: #fffbe6; padding: 10px; border: 2px solid #ff9800; margin: 15px 0;">
          <strong style="font-size: 16px;">$alertType</strong>
        </div>
        
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

        ${intendedDestination != null ? '<div style="background: #ffeb3b; padding: 10px; margin: 10px 0; font-weight: bold;">DESTINATION PRÉVUE : $intendedDestination</div>' : ''}

        <div style="border: 1px solid #000; padding: 10px; margin: 20px 0;">
          <p style="margin: 0;"><strong>MOTIF :</strong> $state</p>
        </div>

        $vitalsSummary

        <p><strong>LOCALISATION ACTUELLE :</strong></p>
        ${position != null ? '<a href="$mapUrl" style="font-size: 18px; font-weight: bold;">OUVRIR LA CARTE D\'INTERVENTION</a><p style="margin-top: 10px; font-size: 14px;">GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}</p>' : '<p style="color: #ff9800; font-weight: bold;">⚠️ NON DISPONIBLE - Service de localisation indisponible</p>'}
        
        <p style="margin-top: 20px;"><strong>CONTACT :</strong> ${user.telephone ?? "N/A"}</p>
      </div>
    ''';
  }
}
