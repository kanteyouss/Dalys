import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/data/providers/mock_health_provider.dart';
import 'package:dalys/data/models/health_data.dart';
import 'package:dalys/features/alertes/services/service_ia.dart';

/// Provider pour la gestion des alertes prédictives IA
class AlertesIAProvider extends ChangeNotifier {
  /// Service IA
  final ServiceIA _serviceIA = ServiceIA();
  
  /// Provider de données de santé
  final MockHealthProvider _healthProvider = MockHealthProvider();
  
  /// Dernières données de santé
  HealthData? _dernieresdonnees;

  /// Liste des alertes IA actives
  List<ModeleAlerte> _alertesIA = [];
  
  /// État de chargement
  bool _chargementEnCours = false;
  
  /// Dernière mise à jour des prédictions
  DateTime? _derniereMiseAJour;
  
  /// Intervalle de mise à jour automatique (en minutes)
  int _intervalleMAJ = 15;
  
  /// Timer pour les mises à jour automatiques
  Timer? _timerMAJ;
  
  /// Stream subscription pour les données de santé
  StreamSubscription<HealthData>? _healthSubscription;

  /// Constructeur
  AlertesIAProvider() {
    _initialiser();
  }

  /// Getters
  List<ModeleAlerte> get alertesIA => List.unmodifiable(_alertesIA);
  bool get chargementEnCours => _chargementEnCours;
  DateTime? get derniereMiseAJour => _derniereMiseAJour;
  int get intervalleMAJ => _intervalleMAJ;
  bool get miseAJourAutomatiqueActive => _timerMAJ?.isActive ?? false;

  /// Initialise le provider
  void _initialiser() {
    // Écouter les données de santé en temps réel
    _healthSubscription = _healthProvider.getHealthDataStream().listen(_onHealthDataChanged);
    
    // Démarrer les prédictions initiales
    _obtenirPredictionsIA();
    
    // Démarrer la mise à jour automatique
    demarrerMiseAJourAutomatique();
  }

  /// Gestionnaire de changement des données de santé
  void _onHealthDataChanged(HealthData donnees) {
    _dernieresdonnees = donnees;
    
    // Déclencher une nouvelle prédiction si les données ont changé significativement
    if (_doitMettreAJourPredictions(donnees)) {
      _obtenirPredictionsIA();
    }
  }

  /// Détermine si une mise à jour des prédictions est nécessaire
  bool _doitMettreAJourPredictions(HealthData nouvellesDonnees) {
    if (_derniereMiseAJour == null) return true;
    
    final tempsDerniereMAJ = DateTime.now().difference(_derniereMiseAJour!);
    if (tempsDerniereMAJ.inMinutes >= _intervalleMAJ) return true;
    
    // Vérifier les changements significatifs
    // Déclencher si SpO2 < 94% ou fréquence respiratoire > 22
    if (nouvellesDonnees.spo2 < 94 || nouvellesDonnees.breathingRate > 22) {
      return true;
    }
    
    return false;
  }

  /// Obtient les prédictions IA
  Future<void> _obtenirPredictionsIA() async {
    if (_chargementEnCours) return;
    
    _chargementEnCours = true;
    notifyListeners();

    try {
      // Récupérer les données médicales actuelles
      final donneesPatient = _preparerDonneesPatient();
      
      // Récupérer les données environnementales (si disponibles)
      final donneesEnv = await _preparerDonneesEnvironnementales();
      
      // Appeler l'IA
      final nouvellesAlertes = await _serviceIA.obtenirPredictionsRisque(
        donneesPatient: donneesPatient,
        donneesEnvironnementales: donneesEnv,
      );
      
      // Mettre à jour les alertes
      _mettreAJourAlertesIA(nouvellesAlertes);
      
      _derniereMiseAJour = DateTime.now();
      debugPrint('🧠 Prédictions IA mises à jour: ${nouvellesAlertes.length} alertes');
      
    } catch (erreur) {
      debugPrint('❌ Erreur prédictions IA: $erreur');
    } finally {
      _chargementEnCours = false;
      notifyListeners();
    }
  }

  /// Prépare les données du patient pour l'IA
  Map<String, dynamic> _preparerDonneesPatient() {
    final donnees = _dernieresdonnees ?? _healthProvider.generateRealisticHealthData();
    
    return {
      'spo2': donnees.spo2.toDouble(),
      'frequence_respiratoire': donnees.breathingRate.toDouble(),
      'pef': donnees.pef,
      'symptomes': donnees.symptoms,
      'niveau_risque': donnees.riskLevel.index,
      'timestamp': DateTime.now().toIso8601String(),
      'patient_id': 'user_local',
      'historique_medical': _obtenirHistoriqueMedical(),
    };
  }

  /// Prépare les données environnementales
  Future<Map<String, dynamic>?> _preparerDonneesEnvironnementales() async {
    // TODO: Intégrer avec le service environnemental quand il sera disponible
    return null;
  }

  /// Obtient l'historique médical pertinent
  Map<String, dynamic> _obtenirHistoriqueMedical() {
    // TODO: Intégrer avec le système de profil patient
    return {
      'conditions_respiratoires': ['asthme'], // Exemple
      'medicaments': [], // À compléter
      'allergies': [], // À compléter
    };
  }

  /// Met à jour la liste des alertes IA
  void _mettreAJourAlertesIA(List<ModeleAlerte> nouvellesAlertes) {
    // Supprimer les anciennes alertes IA
    _alertesIA.removeWhere((alerte) => alerte.type == TypeAlerte.ia);
    
    // Ajouter les nouvelles alertes
    _alertesIA.addAll(nouvellesAlertes);
    
    // Trier par priorité (plus critique en premier)
    _alertesIA.sort((a, b) => b.niveauPriorite.compareTo(a.niveauPriorite));
  }

  /// Démarre la mise à jour automatique
  void demarrerMiseAJourAutomatique() {
    _timerMAJ?.cancel();
    _timerMAJ = Timer.periodic(
      Duration(minutes: _intervalleMAJ),
      (_) => _obtenirPredictionsIA(),
    );
    debugPrint('⏰ Mise à jour automatique IA démarrée (${_intervalleMAJ}min)');
  }

  /// Arrête la mise à jour automatique
  void arreterMiseAJourAutomatique() {
    _timerMAJ?.cancel();
    _timerMAJ = null;
    debugPrint('⏰ Mise à jour automatique IA arrêtée');
  }

  /// Configure l'intervalle de mise à jour
  void configurerIntervalleMAJ(int minutes) {
    if (minutes < 5) minutes = 5; // Minimum 5 minutes
    if (minutes > 60) minutes = 60; // Maximum 1 heure
    
    _intervalleMAJ = minutes;
    
    if (miseAJourAutomatiqueActive) {
      demarrerMiseAJourAutomatique(); // Redémarrer avec le nouvel intervalle
    }
    
    debugPrint('⚙️ Intervalle MAJ IA configuré: ${_intervalleMAJ}min');
  }

  /// Force une mise à jour immédiate
  Future<void> forcerMiseAJour() async {
    await _obtenirPredictionsIA();
  }

  /// Marque une alerte comme acquittée
  void acquitterAlerte(String alerteId) {
    final index = _alertesIA.indexWhere((alerte) => alerte.id == alerteId);
    if (index != -1) {
      _alertesIA.removeAt(index);
      notifyListeners();
      debugPrint('✅ Alerte IA acquittée: $alerteId');
    }
  }

  /// Supprime toutes les alertes IA
  void supprimerToutesAlertes() {
    _alertesIA.clear();
    notifyListeners();
    debugPrint('🗑️ Toutes les alertes IA supprimées');
  }

  /// Obtient le nombre d'alertes par niveau de priorité
  Map<String, int> obtenirStatistiquesAlertes() {
    final stats = <String, int>{
      'critique': 0,
      'elevee': 0,
      'moyenne': 0,
      'faible': 0,
    };
    
    for (final alerte in _alertesIA) {
      if (alerte.niveauPriorite >= 90) {
        stats['critique'] = (stats['critique'] ?? 0) + 1;
      } else if (alerte.niveauPriorite >= 70) {
        stats['elevee'] = (stats['elevee'] ?? 0) + 1;
      } else if (alerte.niveauPriorite >= 50) {
        stats['moyenne'] = (stats['moyenne'] ?? 0) + 1;
      } else {
        stats['faible'] = (stats['faible'] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  /// Test de connectivité IA
  Future<bool> testerConnectiviteIA() async {
    return await _serviceIA.testerConnectivite();
  }

  /// Configure le mode simulation
  void configurerModeSimulation(bool simulation) {
    _serviceIA.configurerModeSimulation(simulation);
  }

  @override
  void dispose() {
    _timerMAJ?.cancel();
    _healthSubscription?.cancel();
    super.dispose();
  }
}