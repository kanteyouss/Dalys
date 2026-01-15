import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/features/alertes/services/service_ia.dart';
import 'package:dalys/features/alertes/services/service_environnemental.dart';
import 'package:dalys/features/alertes/services/service_historique_alertes.dart';
import 'package:dalys/features/alertes/services/service_notifications.dart';

/// Provider principal pour la gestion complète du système d'alertes
/// Coordonne tous les services : IA, environnemental, historique, notifications
class AlertesProvider extends ChangeNotifier {
  /// Services
  final ServiceIA _serviceIA = ServiceIA();
  final ServiceEnvironnemental _serviceEnv = ServiceEnvironnemental();
  final ServiceHistoriqueAlertes _serviceHistorique = ServiceHistoriqueAlertes();
  final ServiceNotifications _serviceNotifications = ServiceNotifications();

  /// État général
  List<ModeleAlerte> _alertesActives = [];
  bool _chargementEnCours = false;
  String? _erreurChargement;
  
  /// État historique
  List<ModeleAlerte> _historiqueComplet = [];
  List<ModeleAlerte> _historiqueFiltre = [];
  Map<String, dynamic> _statistiquesHistorique = {};
  
  /// Filtres actifs
  Map<String, dynamic> _filtresActifs = {};
  
  /// Configuration
  bool _alertesIAActivees = true;
  bool _alertesEnvironnementalesActivees = true;
  bool _notificationsActivees = true;
  bool _modeSimulation = true;
  int _intervalleMAJ = 15; // minutes

  /// Timer pour mise à jour automatique
  Timer? _timerMAJ;

  /// Getters
  List<ModeleAlerte> get alertesActives => List.unmodifiable(_alertesActives);
  List<ModeleAlerte> get historiqueComplet => List.unmodifiable(_historiqueComplet);
  List<ModeleAlerte> get historiqueFiltre => List.unmodifiable(_historiqueFiltre);
  Map<String, dynamic> get statistiquesHistorique => Map.from(_statistiquesHistorique);
  Map<String, dynamic> get filtresActifs => Map.from(_filtresActifs);
  
  bool get chargementEnCours => _chargementEnCours;
  String? get erreurChargement => _erreurChargement;
  bool get alertesIAActivees => _alertesIAActivees;
  bool get alertesEnvironnementalesActivees => _alertesEnvironnementalesActivees;
  bool get notificationsActivees => _notificationsActivees;
  bool get modeSimulation => _modeSimulation;
  int get intervalleMAJ => _intervalleMAJ;

  /// Constructeur
  AlertesProvider() {
    _initialiser();
  }

  /// Initialisation du provider
  Future<void> _initialiser() async {
    debugPrint('🚀 Initialisation du système d\'alertes...');
    
    // Configurer les services
    _serviceIA.configurerModeSimulation(_modeSimulation);
    _serviceEnv.configurerModeSimulation(_modeSimulation);
    
    // Initialiser les notifications
    await _serviceNotifications.initialiser();
    
    // Charger l'historique
    await chargerHistorique();
    
    // Démarrer les alertes actives
    await actualiserAlertesActives();
    
    // Démarrer la mise à jour automatique
    demarrerMiseAJourAutomatique();
    
    debugPrint('✅ Système d\'alertes initialisé');
  }

  /// Charge l'historique complet des alertes
  Future<void> chargerHistorique() async {
    try {
      _historiqueComplet = await _serviceHistorique.obtenirHistorique();
      _historiqueFiltre = List.from(_historiqueComplet);
      _statistiquesHistorique = await _serviceHistorique.obtenirStatistiques();
      
      debugPrint('📖 Historique chargé: ${_historiqueComplet.length} alertes');
      notifyListeners();
      
    } catch (erreur) {
      debugPrint('❌ Erreur chargement historique: $erreur');
      _erreurChargement = 'Erreur lors du chargement de l\'historique';
      notifyListeners();
    }
  }

  /// Actualise les alertes actives (IA + Environnementales)
  Future<void> actualiserAlertesActives() async {
    if (_chargementEnCours) return;
    
    _chargementEnCours = true;
    _erreurChargement = null;
    notifyListeners();

    try {
      final nouvellesAlertes = <ModeleAlerte>[];
      
      // Récupérer les alertes IA si activées
      if (_alertesIAActivees) {
        try {
          final alertesIA = await _obtenirAlertesIA();
          nouvellesAlertes.addAll(alertesIA);
          debugPrint('🧠 ${alertesIA.length} alertes IA récupérées');
        } catch (erreur) {
          debugPrint('⚠️ Erreur alertes IA: $erreur');
        }
      }
      
      // Récupérer les alertes environnementales si activées
      if (_alertesEnvironnementalesActivees) {
        try {
          final alertesEnv = await _serviceEnv.obtenirAlertesEnvironnementales();
          nouvellesAlertes.addAll(alertesEnv);
          debugPrint('🌍 ${alertesEnv.length} alertes environnementales récupérées');
        } catch (erreur) {
          debugPrint('⚠️ Erreur alertes environnementales: $erreur');
        }
      }
      
      // Mettre à jour la liste des alertes actives
      _alertesActives = nouvellesAlertes;
      
      // Trier par priorité
      _alertesActives.sort((a, b) => b.niveauPriorite.compareTo(a.niveauPriorite));
      
      // Sauvegarder dans l'historique
      if (nouvellesAlertes.isNotEmpty) {
        await _serviceHistorique.sauvegarderAlertes(nouvellesAlertes);
        await chargerHistorique(); // Recharger pour mettre à jour
      }
      
      // Envoyer les notifications
      if (_notificationsActivees) {
        await _envoyerNotificationsAlertes(nouvellesAlertes);
      }
      
      debugPrint('✅ ${nouvellesAlertes.length} alertes actives mises à jour');
      
    } catch (erreur) {
      debugPrint('❌ Erreur actualisation alertes: $erreur');
      _erreurChargement = 'Erreur lors de l\'actualisation des alertes';
    } finally {
      _chargementEnCours = false;
      notifyListeners();
    }
  }

  /// Récupère les alertes IA avec données de santé simulées
  Future<List<ModeleAlerte>> _obtenirAlertesIA() async {
    // Simuler des données de santé pour l'IA
    final donneesPatient = {
      'spo2': 92.5, // SpO2 légèrement bas
      'frequence_respiratoire': 23.0, // Légèrement élevée
      'frequence_cardiaque': 85.0,
      'temperature': 36.8,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Ajouter des données environnementales si disponibles
    final donneesEnv = _serviceEnv.dernieresdonneesEnvironnementales;
    
    return await _serviceIA.obtenirPredictionsRisque(
      donneesPatient: donneesPatient,
      donneesEnvironnementales: donneesEnv,
    );
  }

  /// Envoie des notifications pour les nouvelles alertes
  Future<void> _envoyerNotificationsAlertes(List<ModeleAlerte> alertes) async {
    for (final alerte in alertes) {
      // Notification locale
      await _serviceNotifications.afficherNotificationLocale(
        id: alerte.id.hashCode,
        titre: alerte.titre,
        message: alerte.description,
        donnees: alerte.toJson(),
      );
      
      // Notification push pour les alertes critiques
      if (alerte.niveauPriorite >= 90) {
        await _serviceNotifications.envoyerNotificationPush(
          destinataire: 'user_local',
          titre: '🚨 ${alerte.titre}',
          message: alerte.description,
          donnees: alerte.toJson(),
        );
      }
    }
  }

  /// Filtre l'historique selon les critères
  Future<void> appliquerFiltres({
    List<TypeAlerte>? types,
    int? niveauPrioriteMin,
    DateTime? dateDebut,
    DateTime? dateFin,
    List<String>? tags,
    String? recherche,
    int? limite,
  }) async {
    _filtresActifs = {
      'types': types,
      'niveauPrioriteMin': niveauPrioriteMin,
      'dateDebut': dateDebut,
      'dateFin': dateFin,
      'tags': tags,
      'recherche': recherche,
      'limite': limite,
    };
    
    _historiqueFiltre = await _serviceHistorique.filtrerHistorique(
      types: types,
      niveauPrioriteMin: niveauPrioriteMin,
      dateDebut: dateDebut,
      dateFin: dateFin,
      tags: tags,
      recherche: recherche,
      limite: limite,
    );
    
    debugPrint('🔍 Filtre appliqué: ${_historiqueFiltre.length} alertes');
    notifyListeners();
  }

  /// Efface tous les filtres
  void effacerFiltres() {
    _filtresActifs.clear();
    _historiqueFiltre = List.from(_historiqueComplet);
    debugPrint('🔄 Filtres effacés');
    notifyListeners();
  }

  /// Marque une alerte comme acquittée
  Future<void> acquitterAlerte(String alerteId) async {
    // Supprimer des alertes actives
    _alertesActives.removeWhere((alerte) => alerte.id == alerteId);
    
    // Mettre à jour dans l'historique
    final index = _historiqueComplet.indexWhere((alerte) => alerte.id == alerteId);
    if (index != -1) {
      _historiqueComplet[index].mettreAJourStatut(StatutAlerte.resolue);
      await _serviceHistorique.sauvegarderAlerte(_historiqueComplet[index]);
    }
    
    // Annuler la notification
    await _serviceNotifications.annulerNotificationLocale(alerteId.hashCode);
    
    debugPrint('✅ Alerte acquittée: $alerteId');
    notifyListeners();
  }

  /// Supprime une alerte de l'historique
  Future<void> supprimerAlerte(String alerteId) async {
    final success = await _serviceHistorique.supprimerAlerte(alerteId);
    if (success) {
      _historiqueComplet.removeWhere((alerte) => alerte.id == alerteId);
      _historiqueFiltre.removeWhere((alerte) => alerte.id == alerteId);
      _alertesActives.removeWhere((alerte) => alerte.id == alerteId);
      
      // Mettre à jour les statistiques
      _statistiquesHistorique = await _serviceHistorique.obtenirStatistiques();
      
      debugPrint('🗑️ Alerte supprimée: $alerteId');
      notifyListeners();
    }
  }

  /// Vide complètement l'historique
  Future<void> viderHistorique() async {
    final success = await _serviceHistorique.viderHistorique();
    if (success) {
      _historiqueComplet.clear();
      _historiqueFiltre.clear();
      _statistiquesHistorique.clear();
      
      debugPrint('🗑️ Historique vidé');
      notifyListeners();
    }
  }

  /// Configuration des alertes IA
  void configurerAlertesIA(bool actives) {
    _alertesIAActivees = actives;
    debugPrint('⚙️ Alertes IA: ${actives ? 'activées' : 'désactivées'}');
    notifyListeners();
  }

  /// Configuration des alertes environnementales  
  void configurerAlertesEnvironnementales(bool actives) {
    _alertesEnvironnementalesActivees = actives;
    debugPrint('⚙️ Alertes environnementales: ${actives ? 'activées' : 'désactivées'}');
    notifyListeners();
  }

  /// Configuration des notifications
  void configurerNotifications(bool actives) {
    _notificationsActivees = actives;
    debugPrint('⚙️ Notifications: ${actives ? 'activées' : 'désactivées'}');
    notifyListeners();
  }

  /// Configuration du mode simulation
  void configurerModeSimulation(bool simulation) {
    _modeSimulation = simulation;
    _serviceIA.configurerModeSimulation(simulation);
    _serviceEnv.configurerModeSimulation(simulation);
    debugPrint('⚙️ Mode simulation: ${simulation ? 'activé' : 'désactivé'}');
    notifyListeners();
  }

  /// Configuration de l'intervalle de mise à jour
  void configurerIntervalleMAJ(int minutes) {
    if (minutes < 5) minutes = 5;
    if (minutes > 60) minutes = 60;
    
    _intervalleMAJ = minutes;
    
    if (_timerMAJ?.isActive ?? false) {
      demarrerMiseAJourAutomatique(); // Redémarrer avec nouvel intervalle
    }
    
    debugPrint('⚙️ Intervalle MAJ: ${_intervalleMAJ}min');
    notifyListeners();
  }

  /// Démarre la mise à jour automatique
  void demarrerMiseAJourAutomatique() {
    _timerMAJ?.cancel();
    _timerMAJ = Timer.periodic(
      Duration(minutes: _intervalleMAJ),
      (_) => actualiserAlertesActives(),
    );
    debugPrint('⏰ MAJ automatique démarrée (${_intervalleMAJ}min)');
  }

  /// Arrête la mise à jour automatique
  void arreterMiseAJourAutomatique() {
    _timerMAJ?.cancel();
    _timerMAJ = null;
    debugPrint('⏰ MAJ automatique arrêtée');
  }

  /// Force une mise à jour immédiate
  Future<void> forcerMiseAJour() async {
    await actualiserAlertesActives();
  }

  /// Obtient les statistiques générales
  Map<String, dynamic> obtenirStatistiquesGenerales() {
    final alertesParType = <String, int>{};
    final alertesParPriorite = <String, int>{
      'critique': 0,
      'elevee': 0,
      'moyenne': 0,
      'faible': 0,
    };
    
    for (final alerte in _alertesActives) {
      // Par type
      final typeKey = alerte.type.toString().split('.').last;
      alertesParType[typeKey] = (alertesParType[typeKey] ?? 0) + 1;
      
      // Par priorité
      if (alerte.niveauPriorite >= 90) {
        alertesParPriorite['critique'] = alertesParPriorite['critique']! + 1;
      } else if (alerte.niveauPriorite >= 70) {
        alertesParPriorite['elevee'] = alertesParPriorite['elevee']! + 1;
      } else if (alerte.niveauPriorite >= 50) {
        alertesParPriorite['moyenne'] = alertesParPriorite['moyenne']! + 1;
      } else {
        alertesParPriorite['faible'] = alertesParPriorite['faible']! + 1;
      }
    }
    
    return {
      'alertes_actives': _alertesActives.length,
      'historique_total': _historiqueComplet.length,
      'par_type': alertesParType,
      'par_priorite': alertesParPriorite,
      'services_actifs': {
        'ia': _alertesIAActivees,
        'environnemental': _alertesEnvironnementalesActivees,
        'notifications': _notificationsActivees,
      },
      'configuration': {
        'mode_simulation': _modeSimulation,
        'intervalle_maj': _intervalleMAJ,
        'maj_automatique': _timerMAJ?.isActive ?? false,
      },
    };
  }

  /// Exporte l'historique
  Future<String?> exporterHistorique() async {
    return await _serviceHistorique.exporterHistorique();
  }

  /// Importe un historique
  Future<bool> importerHistorique(String jsonString) async {
    final success = await _serviceHistorique.importerHistorique(jsonString);
    if (success) {
      await chargerHistorique();
    }
    return success;
  }

  /// Test de connectivité des services
  Future<Map<String, bool>> testerConnectiviteServices() async {
    return {
      'ia': await _serviceIA.testerConnectivite(),
      'environnemental': await _serviceEnv.testerConnectivite(),
      'notifications': await _serviceNotifications.testerConnectivite(),
    };
  }

  @override
  void dispose() {
    _timerMAJ?.cancel();
    super.dispose();
  }
}