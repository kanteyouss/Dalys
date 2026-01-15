import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/services/service_vocal.dart';
import '../../../data/models/modele_alerte.dart';
import '../models/modele_respiration.dart';

enum PhaseRespiration {
  inspiration,
  retentionPleine,
  expiration,
  retentionVide,
  repos
}

class ServiceRespiration extends ChangeNotifier {
  final ServiceVocal _serviceVocal = ServiceVocal();

  Timer? _timer;
  int _secondesRestantesPhase = 0;
  int _cycleActuel = 0;
  PhaseRespiration _phaseActuelle = PhaseRespiration.repos;
  ModeleTechniqueRespiration? _techniqueActuelle;
  bool _estEnCours = false;

  // Getters
  PhaseRespiration get phaseActuelle => _phaseActuelle;
  int get secondesRestantesPhase => _secondesRestantesPhase;
  int get cycleActuel => _cycleActuel;
  bool get estEnCours => _estEnCours;
  ModeleTechniqueRespiration? get techniqueActuelle => _techniqueActuelle;

  /// Démarre un exercice de respiration
  void demarrerExercice(ModeleTechniqueRespiration technique) {
    _techniqueActuelle = technique;
    _estEnCours = true;
    _cycleActuel = 1;
    _passerAPhase(PhaseRespiration.inspiration);
    notifyListeners();
  }

  /// Arrête l'exercice
  void arreterExercice() {
    _timer?.cancel();
    _estEnCours = false;
    _phaseActuelle = PhaseRespiration.repos;
    _serviceVocal.parler("Exercice terminé. Bien joué.",
        niveau: NiveauNotification.prevention);
    notifyListeners();
  }

  void _passerAPhase(PhaseRespiration nouvellePhase) {
    _phaseActuelle = nouvellePhase;

    switch (nouvellePhase) {
      case PhaseRespiration.inspiration:
        _secondesRestantesPhase = _techniqueActuelle!.dureeInspiration;
        _serviceVocal.parler("Inspirez", niveau: NiveauNotification.prevention);
        break;
      case PhaseRespiration.retentionPleine:
        _secondesRestantesPhase = _techniqueActuelle!.dureeRetentionPleine;
        if (_secondesRestantesPhase > 0) {
          _serviceVocal.parler("Bloquez",
              niveau: NiveauNotification.prevention);
        } else {
          _passerAPhase(PhaseRespiration.expiration);
          return;
        }
        break;
      case PhaseRespiration.expiration:
        _secondesRestantesPhase = _techniqueActuelle!.dureeExpiration;
        _serviceVocal.parler("Expirez lentement",
            niveau: NiveauNotification.prevention);
        break;
      case PhaseRespiration.retentionVide:
        _secondesRestantesPhase = _techniqueActuelle!.dureeRetentionVide;
        if (_secondesRestantesPhase > 0) {
          _serviceVocal.parler("Bloquez",
              niveau: NiveauNotification.prevention);
        } else {
          _cycleActuel++;
          _passerAPhase(PhaseRespiration.inspiration);
          return;
        }
        break;
      default:
        break;
    }

    _demarrerTimerPhase();
  }

  void _demarrerTimerPhase() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondesRestantesPhase > 1) {
        _secondesRestantesPhase--;
        notifyListeners();
      } else {
        timer.cancel();
        _determinerProchainePhase();
      }
    });
  }

  void _determinerProchainePhase() {
    switch (_phaseActuelle) {
      case PhaseRespiration.inspiration:
        _passerAPhase(PhaseRespiration.retentionPleine);
        break;
      case PhaseRespiration.retentionPleine:
        _passerAPhase(PhaseRespiration.expiration);
        break;
      case PhaseRespiration.expiration:
        _passerAPhase(PhaseRespiration.retentionVide);
        break;
      case PhaseRespiration.retentionVide:
        _cycleActuel++;
        _passerAPhase(PhaseRespiration.inspiration);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
