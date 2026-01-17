import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/data/services/auth_service.dart';
import 'package:dalys/data/services/emergency_service.dart';
import 'package:dalys/data/services/medication_service.dart';
import '../services/service_ia.dart';

/// Événement d'urgence pour la communication avec l'UI
class EmergencyEvent {
  final String title;
  final String description;
  EmergencyEvent(this.title, this.description);
}

/// Contrôleur principal pour la gestion des alertes médicales et environnementales
class ControleurAlertes extends ChangeNotifier {
  DateTime? _lastEmergencyTrigger;
  static const Duration _emergencyCooldown = Duration(minutes: 1);
  final AuthService _authService = AuthService();
  final List<ModeleAlerte> _listeAlertes = [];
  bool _estEnChargement = false;
  String? _messageErreur;
  bool _estEnModeSimulation = true;
  MedicationService? _medicationService;
  dynamic _settingsService;

  void setSettingsService(dynamic service) {
    _settingsService = service;
  }

  bool _estAutorise(String categorie) {
    if (_settingsService == null) return true;
    return _settingsService.isNotificationEnabled(categorie);
  }

  // Filtres et recherche
  Set<TypeAlerte> _filtresType = {};
  Set<NiveauSeverite> _filtresSeverite = {};
  bool _afficherSeulementNonLues = false;
  String _termeRecherche = '';

  // Stream pour notifier l'UI des alertes critiques
  final _emergencyStreamController =
      StreamController<EmergencyEvent>.broadcast();
  Stream<EmergencyEvent> get emergencyStream =>
      _emergencyStreamController.stream;

  // Getters
  bool get estEnModeSimulation => _estEnModeSimulation;
  bool get estEnChargement => _estEnChargement;
  String? get messageErreur => _messageErreur;
  String get termeRecherche => _termeRecherche;
  bool get afficherSeulementNonLues => _afficherSeulementNonLues;
  Set<TypeAlerte> get filtresTypeActifs => _filtresType;
  Set<NiveauSeverite> get filtresSeveriteActifs => _filtresSeverite;

  int? get _currentUserId => _authService.currentUser?.id;

  List<ModeleAlerte> get toutesLesAlertes {
    final userId = _currentUserId;
    if (userId == null) return [];
    return _listeAlertes
        .where((a) => a.idUtilisateur == userId.toString())
        .toList();
  }

  List<ModeleAlerte> get alertesFiltrees {
    List<ModeleAlerte> resultat = toutesLesAlertes;

    if (_filtresType.isNotEmpty) {
      resultat = resultat.where((a) => _filtresType.contains(a.type)).toList();
    }
    if (_filtresSeverite.isNotEmpty) {
      // Note: ModeleAlerte might not have severite directly, but we can map it or ignore for now
      // If ModeleAlerte has a way to get severite, use it here.
    }
    if (_afficherSeulementNonLues) {
      resultat =
          resultat.where((a) => a.statut == StatutAlerte.nouvelle).toList();
    }
    if (_termeRecherche.isNotEmpty) {
      resultat = resultat
          .where((a) =>
              a.titre.toLowerCase().contains(_termeRecherche.toLowerCase()))
          .toList();
    }

    return resultat
      ..sort((a, b) => b.niveauPriorite.compareTo(a.niveauPriorite));
  }

  int get nombreTotalAlertes => alertesFiltrees.length;
  int get nombreAlertesNonLues =>
      alertesFiltrees.where((a) => a.statut == StatutAlerte.nouvelle).length;
  int get nombreAlertesCritiques => alertesFiltrees
      .where((a) => a.statut == StatutAlerte.nouvelle && a.estUrgente)
      .length;

  // Méthodes
  Future<void> initialiser() async {
    _estEnChargement = true;
    _messageErreur = null;
    notifyListeners();
    try {
      if (_estEnModeSimulation && _listeAlertes.isEmpty) {
        await genererDonneesDemo();
      }

      // S'abonner aux urgences
      EmergencyService().onEmergency.listen((description) {
        _creerAlerteSiNecessaire(
          idPrefix: 'emergency_auto',
          titre: '🚨 URGENCE DÉCLENCHÉE',
          description: description,
          type: TypeAlerte.critique,
          priorite: 100,
          tags: ['urgence', 'sos', 'automatique'],
        );
      });
    } catch (e) {
      _messageErreur = e.toString();
    } finally {
      _estEnChargement = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() => initialiser();

  void ajouterAlerte(ModeleAlerte alerte) {
    // Vérifier les filtres utilisateur
    String categorie = 'alert';
    if (alerte.type == TypeAlerte.medicament) categorie = 'medication';
    if (alerte.type == TypeAlerte.rendezvous) categorie = 'medication';
    if (alerte.niveauNotification == NiveauNotification.prevention) {
      categorie = 'forecast';
    }

    if (!_estAutorise(categorie)) {
      debugPrint('🚫 Alerte filtrée par l\'utilisateur: ${alerte.titre}');
      return;
    }

    _listeAlertes.add(alerte);
    if (alerte.estUrgente) {
      _gererAlerteCritique(alerte);
    }
    notifyListeners();
  }

  void setMedicationService(MedicationService service) {
    _medicationService = service;
  }

  void _gererAlerteCritique(ModeleAlerte alerte) {
    _emergencyStreamController
        .add(EmergencyEvent(alerte.titre, alerte.description));
    debugPrint('🚨 Alerte critique détectée: ${alerte.titre}');
  }

  Future<void> analyserDonneesSante(dynamic healthData) async {
    debugPrint(
        '🔍 ControleurAlertes: analyserDonneesSante() appelé avec SpO2=${healthData.spo2}');

    // 1. Analyse IA des prédictions de risque
    final predictions = await ServiceIA().obtenirPredictionsRisque(
      donneesPatient: {
        'spo2': healthData.spo2.toDouble(),
        'frequence_respiratoire': healthData.breathingRate.toDouble(),
      },
    );

    for (var alerte in predictions) {
      ajouterAlerte(
          alerte.copierAvec(idUtilisateur: _currentUserId.toString()));

      // Si le score de risque est critique (> 60) ou si c'est une alerte critique
      final riskScore = alerte.metadonnees['risk_score'] as double? ?? 0;
      if (riskScore > 60 || alerte.type == TypeAlerte.critique) {
        String recommendation =
            'Score de risque élevé (${riskScore.toInt()}/100). ';
        recommendation += alerte.description;

        if (_medicationService != null) {
          // Identifier les traitements critiques (ex: Ventoline pour le souffle)
          _medicationService!.highlightMedication('Ventoline', recommendation);
        }

        // Déclenchement automatique si TRÈS critique
        if (riskScore > 80 || healthData.spo2 < 90) {
          await _triggerAutomaticEmergency(
            'Risque IA Critique (${riskScore.toInt()}%) : ${alerte.titre}',
            healthData,
          );
        }
      }
    }

    // 2. Analyse IA de corrélation (Observance + Santé)
    if (_medicationService != null) {
      final iaAlertes = await ServiceIA().analyserObservanceEtSante(
        _medicationService!.medications,
        {
          'spo2': healthData.spo2.toDouble(),
          'pef': healthData.pef.toDouble(),
        },
      );

      for (var alerte in iaAlertes) {
        ajouterAlerte(
            alerte.copierAvec(idUtilisateur: _currentUserId.toString()));

        if (alerte.titre.contains('Oubli')) {
          for (var med in _medicationService!.medications) {
            if (!med.isTakenToday) {
              _medicationService!
                  .highlightMedication(med.name, alerte.description);
            }
          }
        }
      }
    }
  }

  void _creerAlerteSiNecessaire({
    required String idPrefix,
    required String titre,
    required String description,
    required TypeAlerte type,
    required int priorite,
    required List<String> tags,
  }) {
    final userId = _currentUserId;
    if (userId == null) return;

    final nouvelleAlerte = ModeleAlerte(
      id: '${idPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      titre: titre,
      description: description,
      type: type,
      dateCreation: DateTime.now(),
      statut: StatutAlerte.nouvelle,
      niveauPriorite: priorite,
      tags: tags,
      idUtilisateur: userId.toString(),
    );
    ajouterAlerte(nouvelleAlerte);
  }

  /// Déclenche automatiquement le protocole d'urgence pour les cas très critiques
  Future<void> _triggerAutomaticEmergency(
      String stateDescription, dynamic healthData) async {
    // Vérifier le cooldown pour éviter les envois multiples
    final now = DateTime.now();
    if (_lastEmergencyTrigger != null) {
      final timeSinceLastTrigger = now.difference(_lastEmergencyTrigger!);
      if (timeSinceLastTrigger < _emergencyCooldown) {
        debugPrint(
            '⚠️ Urgence automatique ignorée (cooldown actif: ${_emergencyCooldown.inMinutes - timeSinceLastTrigger.inMinutes} min restantes)');
        return;
      }
    }

    // Récupérer l'utilisateur actuel
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint(
          '❌ Impossible de déclencher l\'urgence: utilisateur non connecté');
      return;
    }

    debugPrint('🚨 DÉCLENCHEMENT AUTOMATIQUE D\'URGENCE - $stateDescription');
    _lastEmergencyTrigger = now;

    // Déclencher le protocole d'urgence SANS compte à rebours
    await EmergencyService().triggerEmergencyProtocol(
      user,
      stateDescription,
      recentHistory: healthData != null ? [healthData] : null,
      isAutomatic: true, // ← IMPORTANT : Marquer comme automatique
    );
  }

  void definirTermeRecherche(String terme) {
    _termeRecherche = terme;
    notifyListeners();
  }

  void basculerModeSimulation(bool actif) {
    _estEnModeSimulation = actif;
    initialiser();
  }

  void definirFiltresType(Set<TypeAlerte> filtres) {
    _filtresType = filtres;
    notifyListeners();
  }

  void definirFiltresSeverite(Set<NiveauSeverite> filtres) {
    _filtresSeverite = filtres;
    notifyListeners();
  }

  void definirAfficherSeulementNonLues(bool valeur) {
    _afficherSeulementNonLues = valeur;
    notifyListeners();
  }

  void marquerCommeLu(String id) {
    final index = _listeAlertes.indexWhere((a) => a.id == id);
    if (index != -1) {
      _listeAlertes[index].marquerCommeLue();
      notifyListeners();
    }
  }

  void marquerCommeNonLu(String id) {
    final index = _listeAlertes.indexWhere((a) => a.id == id);
    if (index != -1) {
      _listeAlertes[index].mettreAJourStatut(StatutAlerte.nouvelle);
      notifyListeners();
    }
  }

  void dupliquerAlerte(String id) {
    final index = _listeAlertes.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alerte = _listeAlertes[index];
      final nouvelleAlerte = alerte
          .copierAvec(
            statut: StatutAlerte.nouvelle,
          )
          .copierAvec(
              // On change l'ID pour qu'il soit unique
              );

      // Note: copierAvec doesn't allow changing ID easily if it's final and not in copierAvec
      // Let's use the factory or just create a new one if needed.
      // Actually ModeleAlerte.id is final.

      final duplicate = ModeleAlerte(
        id: '${alerte.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
        titre: '${alerte.titre} (Copie)',
        description: alerte.description,
        type: alerte.type,
        dateCreation: DateTime.now(),
        statut: StatutAlerte.nouvelle,
        niveauPriorite: alerte.niveauPriorite,
        idUtilisateur: alerte.idUtilisateur,
        tags: List.from(alerte.tags),
        metadonnees: Map.from(alerte.metadonnees),
        actions: Map.from(alerte.actions),
      );

      ajouterAlerte(duplicate);
    }
  }

  void marquerToutCommeLu() {
    for (var a in toutesLesAlertes) {
      a.marquerCommeLue();
    }
    notifyListeners();
  }

  void effacerTousLesFiltres() {
    _filtresType.clear();
    _filtresSeverite.clear();
    _afficherSeulementNonLues = false;
    _termeRecherche = '';
    notifyListeners();
  }

  void supprimerAlerte(String id) {
    _listeAlertes.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> genererDonneesDemo() async {
    final userId = _currentUserId;
    if (userId == null) return;
    _listeAlertes.add(ModeleAlerte.critique(
      id: 'demo_crit_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Alerte Démo Critique',
      description: 'Ceci est une alerte de démonstration.',
    ).copierAvec(idUtilisateur: userId.toString()));
  }

  @override
  void dispose() {
    _emergencyStreamController.close();
    super.dispose();
  }
}
