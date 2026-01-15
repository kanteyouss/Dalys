import '../models/donnees_symptomes.dart';
import '../models/entree_symptome_quotidien.dart';
import '../models/health_data.dart';

/// Service IA simulé pour l'analyse des risques
/// Combine symptômes et données vitales pour des prédictions
class ServicePredictionIA {
  static final ServicePredictionIA _instance = ServicePredictionIA._internal();
  factory ServicePredictionIA() => _instance;
  ServicePredictionIA._internal();

  /// Analyse les symptômes et retourne une prédiction
  Future<PredictionIA> analyserSymptomes({
    required DonneesSymptomes symptomes,
    HealthData? donneesVitales,
    List<EntreeSymptomeQuotidien>? historique,
  }) async {
    // Simulation de traitement IA
    await Future.delayed(const Duration(milliseconds: 800));

    int scoreRisque = 0;
    final List<String> recommandations = [];
    final List<String> facteursRisque = [];

    // 1. Analyse des symptômes actuels (40% du score)
    if (symptomes.estGrave) {
      scoreRisque += 35;
      facteursRisque.add("Symptômes sévères détectés");
      recommandations.add("Arrêtez toute activité physique immédiatement.");
      recommandations.add("Utilisez votre traitement de secours si prescrit.");
    } else if (symptomes.aSymptomes) {
      scoreRisque += 15;
      recommandations.add("Surveillez l'évolution de vos symptômes.");
      recommandations.add("Reposez-vous aujourd'hui.");
    }

    // Symptômes spécifiques
    if (symptomes.nomsSymptomes.contains('essoufflement')) {
      scoreRisque += 10;
      recommandations.add("Pratiquez la respiration lèvres pincées.");
    }
    if (symptomes.nomsSymptomes.contains('fievre')) {
      scoreRisque += 5;
      recommandations.add("Hydratez-vous abondamment.");
    }

    // 2. Analyse des données vitales (40% du score)
    if (donneesVitales != null) {
      if (donneesVitales.spo2 < 92) {
        scoreRisque += 30;
        facteursRisque.add("SpO₂ critique (${donneesVitales.spo2}%)");
        recommandations.add("⚠️ SpO₂ très basse : consultez un médecin.");
      } else if (donneesVitales.spo2 < 95) {
        scoreRisque += 15;
        recommandations.add("Votre oxygénation est légèrement basse.");
      }

      if (donneesVitales.breathingRate > 25) {
        scoreRisque += 20;
        facteursRisque.add("Fréquence respiratoire élevée");
      }
    } else {
      recommandations.add("Prenez vos mesures vitales pour une analyse plus précise.");
    }

    // 3. Analyse de l'historique (20% du score)
    if (historique != null && historique.isNotEmpty) {
      // Vérifier si les symptômes persistent depuis plusieurs jours
      int joursConsecutifs = 0;
      for (var entree in historique) {
        if (entree.aSymptomesGraves) joursConsecutifs++;
      }

      if (joursConsecutifs >= 2) {
        scoreRisque += 15;
        facteursRisque.add("Symptômes persistants depuis $joursConsecutifs jours");
        recommandations.add("Vos symptômes persistent, une consultation est conseillée.");
      }
    }

    // Normalisation du score (max 100)
    scoreRisque = scoreRisque.clamp(0, 100);

    // Détermination du niveau de risque
    String niveauRisque;
    bool doitCreerAlerte = false;
    String? messageAlerte;

    if (scoreRisque >= 70) {
      niveauRisque = 'eleve';
      doitCreerAlerte = true;
      messageAlerte = "Risque élevé détecté : ${facteursRisque.join(', ')}";
    } else if (scoreRisque >= 40) {
      niveauRisque = 'moyen';
    } else {
      niveauRisque = 'faible';
    }

    // Ajout de recommandations génériques si vide
    if (recommandations.isEmpty) {
      recommandations.add("Continuez à maintenir vos bonnes habitudes !");
      recommandations.add("Pensez à aérer votre logement.");
    }

    return PredictionIA(
      scoreRisque: scoreRisque,
      niveauRisque: niveauRisque,
      recommandations: recommandations,
      doitCreerAlerte: doitCreerAlerte,
      messageAlerte: messageAlerte,
      analyse: {
        'facteurs_risque': facteursRisque,
        'donnees_vitales_incluses': donneesVitales != null,
      },
    );
  }
}
