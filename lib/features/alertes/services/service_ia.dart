import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dalys/data/models/modele_alerte.dart';

/// Service pour la gestion des alertes prédictives IA
/// Simule les appels API vers le serveur d'intelligence artificielle (Django/Flask)
class ServiceIA {
  /// Instance singleton
  static final ServiceIA _instance = ServiceIA._internal();
  factory ServiceIA() => _instance;
  ServiceIA._internal();

  /// URL de base du serveur IA (à configurer selon l'environnement)
  static const String _baseUrl = 'http://localhost:8000/api/v1/predictions';
  
  /// Indique si le service est en mode simulation
  bool _modeSimulation = true;

  /// Active ou désactive le mode simulation
  void configurerModeSimulation(bool simulation) {
    _modeSimulation = simulation;
    debugPrint('🧠 Service IA configuré en mode ${simulation ? 'simulation' : 'production'}');
  }

  /// Récupère les prédictions de risque depuis le serveur IA
  /// [donneesPatient] : Données médicales du patient (SpO2, fréquence respiratoire, etc.)
  /// [donneesEnvironnementales] : Données environnementales (pollution, température, etc.)
  Future<List<ModeleAlerte>> obtenirPredictionsRisque({
    required Map<String, dynamic> donneesPatient,
    Map<String, dynamic>? donneesEnvironnementales,
  }) async {
    if (_modeSimulation) {
      return await _simulerPredictionsIA(donneesPatient, donneesEnvironnementales);
    }

    try {
      // TODO: Implémenter l'appel HTTP réel quand le backend sera disponible
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl/predict-risk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_data': donneesPatient,
          'environmental_data': donneesEnvironnementales ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseAlertes(data['predictions']);
      }
      */
      
      debugPrint('⚠️ Serveur IA non disponible, utilisation du mode simulation');
      return await _simulerPredictionsIA(donneesPatient, donneesEnvironnementales);
      
    } catch (erreur) {
      debugPrint('❌ Erreur service IA: $erreur');
      return [];
    }
  }

  /// Simule les prédictions IA avec des données réalistes
  Future<List<ModeleAlerte>> _simulerPredictionsIA(
    Map<String, dynamic> donneesPatient,
    Map<String, dynamic>? donneesEnvironnementales,
  ) async {
    // Simulation d'un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));

    final alertes = <ModeleAlerte>[];
    final maintenant = DateTime.now();

    // Analyser SpO2
    final spo2 = donneesPatient['spo2'] as double? ?? 95.0;
    if (spo2 < 90) {
      alertes.add(ModeleAlerte(
        id: 'ia_spo2_${maintenant.millisecondsSinceEpoch}',
        titre: 'Risque critique de désaturation',
        description: 'L\'IA détecte un risque élevé de crise respiratoire basé sur votre SpO₂ actuel (${spo2.toStringAsFixed(1)}%). '
                    'Une consultation médicale urgente est recommandée.',
        type: TypeAlerte.critique,
        dateCreation: maintenant,
        niveauPriorite: 100,
        donneesMedicales: {
          'spo2_actuel': spo2,
          'seuil_critique': 90,
          'confidence_score': 0.92,
          'risk_factors': ['hypoxémie', 'insuffisance_respiratoire'],
        },
        recommandations: [
          'Consultez immédiatement un médecin',
          'Évitez tout effort physique',
          'Surveillez votre respiration',
        ],
        tags: ['ia', 'spo2', 'critique', 'hypoxémie'],
        source: 'IA Prédictive v2.1',
      ));
    } else if (spo2 < 94) {
      alertes.add(ModeleAlerte(
        id: 'ia_spo2_${maintenant.millisecondsSinceEpoch}',
        titre: 'Alerte SpO₂ : Surveillance renforcée',
        description: 'L\'IA recommande une surveillance accrue. Votre SpO₂ (${spo2.toStringAsFixed(1)}%) '
                    'est en dessous des valeurs optimales.',
        type: TypeAlerte.ia,
        niveauPriorite: 75,
        dateCreation: maintenant,
        donneesMedicales: {
          'spo2_actuel': spo2,
          'seuil_optimal': 95,
          'confidence_score': 0.78,
          'tendance': 'décroissante',
        },
        recommandations: [
          'Évitez les efforts physiques intenses',
          'Surveillez votre respiration',
          'Consultez si les symptômes persistent',
        ],
        tags: ['ia', 'spo2', 'surveillance'],
        source: 'IA Prédictive v2.1',
      ));
    }

    // Analyser la fréquence respiratoire
    final freqResp = donneesPatient['frequence_respiratoire'] as double? ?? 18.0;
    if (freqResp > 25) {
      alertes.add(ModeleAlerte(
        id: 'ia_freq_${maintenant.millisecondsSinceEpoch}',
        titre: 'Détection de tachypnée',
        description: 'L\'IA a détecté une fréquence respiratoire élevée (${freqResp.toInt()} bpm). '
                    'Cela peut indiquer une détresse respiratoire.',
        type: TypeAlerte.ia,
        niveauPriorite: 80,
        dateCreation: maintenant,
        donneesMedicales: {
          'frequence_actuelle': freqResp,
          'frequence_normale': '12-20 bpm',
          'confidence_score': 0.85,
          'pattern_detection': 'tachypnée',
        },
        recommandations: [
          'Pratiquez des exercices de respiration',
          'Éliminez les facteurs de stress',
          'Consultez si la fréquence reste élevée',
        ],
        tags: ['ia', 'fréquence', 'tachypnée'],
        source: 'IA Prédictive v2.1',
      ));
    }

    // Prédiction basée sur les données environnementales
    if (donneesEnvironnementales != null) {
      final pollution = donneesEnvironnementales['aqi'] as double? ?? 50.0;
      if (pollution > 100) {
        alertes.add(ModeleAlerte(
          id: 'ia_env_${maintenant.millisecondsSinceEpoch}',
          titre: 'Risque environnemental détecté',
          description: 'L\'IA corrèle vos données médicales avec la pollution actuelle (AQI: ${pollution.toInt()}). '
                      'Risque accru de complications respiratoires.',
          type: TypeAlerte.ia,
          niveauPriorite: 70,
          dateCreation: maintenant,
          donneesMedicales: {
            'aqi_actuel': pollution,
            'seuil_risque': 100,
            'correlation_score': 0.73,
            'patient_sensitivity': 'élevée',
          },
          recommandations: [
            'Limitez les sorties extérieures',
            'Utilisez un masque anti-pollution',
            'Restez hydraté',
            'Surveillez vos symptômes',
          ],
          tags: ['ia', 'environnement', 'pollution', 'prévention'],
          source: 'IA Prédictive v2.1',
        ));
      }
    }

    debugPrint('🧠 IA a généré ${alertes.length} prédictions');
    return alertes;
  }



  /// Envoie des données pour l'entraînement du modèle IA
  Future<bool> envoyerDonneesEntrainement({
    required Map<String, dynamic> donneesPatient,
    required String resultatReel,
    Map<String, dynamic>? feedback,
  }) async {
    if (_modeSimulation) {
      debugPrint('📊 Données d\'entraînement simulées envoyées');
      return true;
    }

    try {
      // TODO: Implémenter l'envoi réel des données d'entraînement
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl/training-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_data': donneesPatient,
          'actual_outcome': resultatReel,
          'feedback': feedback ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
      */
      return true;
    } catch (erreur) {
      debugPrint('❌ Erreur envoi données IA: $erreur');
      return false;
    }
  }

  /// Obtient les métriques de performance du modèle IA
  Future<Map<String, dynamic>> obtenirMetriquesIA() async {
    if (_modeSimulation) {
      return {
        'accuracy': 0.87,
        'precision': 0.82,
        'recall': 0.89,
        'f1_score': 0.85,
        'last_training': '2024-11-10T14:30:00Z',
        'model_version': 'v2.1',
        'predictions_count': 1247,
      };
    }

    try {
      // TODO: Implémenter la récupération des métriques réelles
      return {};
    } catch (erreur) {
      debugPrint('❌ Erreur métriques IA: $erreur');
      return {};
    }
  }

  /// Test de connectivité avec le serveur IA
  Future<bool> testerConnectivite() async {
    if (_modeSimulation) {
      debugPrint('🧪 Test de connectivité IA (simulation): OK');
      return true;
    }

    try {
      // TODO: Implémenter le test de connectivité réel
      /*
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
      */
      return false;
    } catch (erreur) {
      debugPrint('❌ Erreur connectivité IA: $erreur');
      return false;
    }
  }
}