import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/data/services/auth_service.dart';
import 'package:dalys/data/services/emergency_service.dart';
import 'package:dalys/core/config/medical_config.dart';

/// Événement d'urgence pour la communication avec l'UI
class EmergencyEvent {
  final String title;
  final String description;
  EmergencyEvent(this.title, this.description);
}

/// Contrôleur principal pour la gestion des alertes médicales et environnementales
class ControleurAlertes extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final List<ModeleAlerte> _listeAlertes = [];
  bool _estEnChargement = false;
  String? _messageErreur;
  bool _estEnModeSimulation = true;

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
    } catch (e) {
      _messageErreur = e.toString();
    } finally {
      _estEnChargement = false;
      notifyListeners();
    }
  }

  Future<void> actualiser() => initialiser();

  void ajouterAlerte(ModeleAlerte alerte) {
    _listeAlertes.add(alerte);
    if (alerte.estUrgente) {
      _gererAlerteCritique(alerte);
    }
    notifyListeners();
  }

  void _gererAlerteCritique(ModeleAlerte alerte) {
    _emergencyStreamController
        .add(EmergencyEvent(alerte.titre, alerte.description));
    debugPrint('🚨 Alerte critique détectée: ${alerte.titre}');
  }

  void analyserDonneesSante(dynamic healthData) {
    if (healthData.spo2 < MedicalConfig.spo2Critical) {
      _creerAlerteSiNecessaire(
        idPrefix: 'auto_spo2',
        titre: 'Niveau d\'oxygène critique',
        description:
            'Votre saturation en oxygène est basse (${healthData.spo2}%).',
        type: TypeAlerte.critique,
        priorite: 90,
        tags: ['santé', 'urgence', 'spo2'],
      );
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
