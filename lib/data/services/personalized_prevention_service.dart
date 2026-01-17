import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/actionable_recommendation.dart';
import 'environmental_service.dart';

/// Service de prévention personnalisée basée sur le profil du patient
class PersonalizedPreventionService {
  static final PersonalizedPreventionService _instance =
      PersonalizedPreventionService._internal();
  factory PersonalizedPreventionService() => _instance;
  PersonalizedPreventionService._internal();

  final EnvironmentalService _envService = EnvironmentalService();

  /// Génère des conseils SPÉCIFIQUES au patient
  Future<List<PreventionAdvice>> getPersonalizedAdvice(
    PatientRiskProfile profile,
    HealthData currentData,
    List<HealthData> history,
  ) async {
    final advice = <PreventionAdvice>[];

    // 1️⃣ Conseils basés sur les patterns temporels
    final patternAdvice = _getPatternBasedAdvice(profile);
    advice.addAll(patternAdvice);

    // 2️⃣ Conseils basés sur les triggers environnementaux
    final triggerAdvice = await _getTriggerBasedAdvice(profile);
    advice.addAll(triggerAdvice);

    // 3️⃣ Conseils basés sur l'anomalie personnelle
    final anomalyAdvice = _getAnomalyBasedAdvice(profile, currentData);
    if (anomalyAdvice != null) advice.add(anomalyAdvice);

    // 4️⃣ Conseils basés sur le risque horaire
    final timeAdvice = _getTimeBasedAdvice(profile);
    if (timeAdvice != null) advice.add(timeAdvice);

    return advice;
  }

  /// Génère des recommandations actionnables
  Future<List<ActionableRecommendation>> getActionableRecommendations(
    PatientRiskProfile profile,
    HealthData currentData,
    List<HealthData> history,
  ) async {
    final recommendations = <ActionableRecommendation>[];

    // Analyser l'état actuel
    final isAnomalous = profile.isAnomalousForThisPatient(
      currentData.spo2,
      currentData.breathingRate,
      currentData.pef,
    );

    if (isAnomalous) {
      // SpO₂ anormalement bas pour ce patient
      if (currentData.spo2 < profile.baselineSpo2 - 2) {
        recommendations.add(ActionableRecommendation(
          action:
              'Pratiquez 10 respirations profondes en position assise confortable',
          deadline: DateTime.now().add(Duration(hours: 2)),
          estimatedDuration: Duration(minutes: 5),
          isCritical: true,
          successCriteria:
              'Votre SpO₂ devrait remonter de 1-2% après cet exercice',
          category: 'exercise',
          priority: 9,
        ));

        recommendations.add(ActionableRecommendation(
          action:
              'Buvez 500ml d\'eau lentement sur 30 minutes, puis 200ml/heure jusqu\'à 18h',
          deadline: DateTime.now().add(Duration(minutes: 30)),
          estimatedDuration: Duration(minutes: 30),
          isCritical: false,
          successCriteria: 'Amélioration de l\'oxygénation tissulaire',
          category: 'lifestyle',
          priority: 7,
        ));
      }

      // Fréquence respiratoire élevée
      if (currentData.breathingRate > profile.baselineBreathingRate + 4) {
        recommendations.add(ActionableRecommendation(
          action:
              'Exercice de respiration lèvres pincées: inspirez 2s, expirez 4s, répétez 10 fois',
          deadline: DateTime.now().add(Duration(minutes: 30)),
          estimatedDuration: Duration(minutes: 5),
          isCritical: true,
          successCriteria:
              'Fréquence respiratoire devrait diminuer de 2-3 bpm',
          category: 'exercise',
          priority: 10,
        ));
      }
    }

    // Recommandations préventives basées sur les triggers
    for (var trigger in profile.triggers) {
      if (trigger.type == 'pollution') {
        final envData = await _envService.getCurrentData();
        if (envData != null && envData.aqi > trigger.threshold) {
          if (trigger.preventiveMedication != null) {
            recommendations.add(ActionableRecommendation(
              action: 'Prenez ${trigger.preventiveMedication} MAINTENANT',
              deadline: DateTime.now().add(Duration(minutes: 15)),
              estimatedDuration: Duration(minutes: 2),
              isCritical: true,
              successCriteria: 'Prévention de la crise dans les ${trigger.delayHours}h',
              category: 'medication',
              priority: 10,
            ));
          }

          recommendations.add(ActionableRecommendation(
            action: 'Annulez vos sorties extérieures prévues aujourd\'hui',
            deadline: DateTime.now().add(Duration(hours: 1)),
            estimatedDuration: Duration(minutes: 10),
            isCritical: false,
            successCriteria: 'Éviter l\'exposition à la pollution (AQI: ${envData.aqi})',
            category: 'lifestyle',
            priority: 8,
          ));
        }
      }
    }

    // Recommandations basées sur l'heure de la journée
    final currentRisk = profile.getCurrentTimeRisk();
    if (currentRisk.riskScore > 60) {
      recommendations.add(ActionableRecommendation(
        action:
            'Préparez votre environnement: fenêtres fermées, humidificateur activé',
        deadline: DateTime.now().add(Duration(minutes: 30)),
        estimatedDuration: Duration(minutes: 10),
        isCritical: false,
        successCriteria:
            'Environnement optimal pour la période ${currentRisk.period}',
        category: 'lifestyle',
        priority: 6,
      ));
    }

    // Surveillance renforcée si tendance négative
    if (history.length >= 3) {
      final last3Days = history.sublist(history.length - 3);
      final avgSpo2 = last3Days.map((d) => d.spo2).reduce((a, b) => a + b) / 3;

      if (avgSpo2 < profile.baselineSpo2 - 1) {
        recommendations.add(ActionableRecommendation(
          action:
              'Mesurez vos paramètres 2 fois par jour (matin 8h + soir 20h) au lieu d\'1 fois',
          deadline: DateTime.now().add(Duration(hours: 12)),
          estimatedDuration: Duration(minutes: 5),
          isCritical: false,
          successCriteria:
              'Surveillance renforcée pendant 7 jours pour détecter toute aggravation',
          category: 'monitoring',
          priority: 7,
        ));
      }
    }

    // Trier par priorité décroissante
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations;
  }

  /// Conseils basés sur les patterns identifiés
  List<PreventionAdvice> _getPatternBasedAdvice(PatientRiskProfile profile) {
    final advice = <PreventionAdvice>[];

    for (var pattern in profile.patterns) {
      if (pattern.type == 'weekly_decline') {
        final dayOfWeek = pattern.parameters['day_of_week'] as int;
        final today = DateTime.now().weekday;

        // Si on est la veille du jour à risque
        if (today == (dayOfWeek == 1 ? 7 : dayOfWeek - 1)) {
          final dayNames = [
            '',
            'lundi',
            'mardi',
            'mercredi',
            'jeudi',
            'vendredi',
            'samedi',
            'dimanche'
          ];

          advice.add(PreventionAdvice(
            title: '📅 Préparation pour demain',
            message:
                'Vos données montrent que vous avez tendance à baisser le ${dayNames[dayOfWeek]}. '
                'Préparez votre traitement préventif dès ce soir.',
            timing: 'Aujourd\'hui 20h',
            evidence:
                'Basé sur ${pattern.occurrences} ${dayNames[dayOfWeek]}s analysés où SpO₂ moyen = ${pattern.parameters['average_spo2'].toStringAsFixed(1)}%',
            actions: [
              'Prenez votre traitement préventif ce soir',
              'Préparez vos médicaments de secours (accessibles)',
              'Évitez les activités physiques intenses demain',
              'Dormez 8h minimum cette nuit',
            ],
          ));
        }
      }

      if (pattern.type == 'evening_deterioration') {
        final currentHour = DateTime.now().hour;
        if (currentHour >= 15 && currentHour < 17) {
          advice.add(PreventionAdvice(
            title: '🌆 Anticipation soirée',
            message:
                'Vos paramètres ont tendance à se dégrader en soirée. '
                'Prenez vos dispositions MAINTENANT.',
            timing: 'Dans les 2 prochaines heures',
            evidence:
                'Pattern détecté sur ${pattern.occurrences} soirées analysées',
            actions: [
              'Prenez votre traitement à 17h au lieu d\'attendre 20h',
              'Dînez léger et tôt (avant 19h)',
              'Préparez votre chambre: aération, humidificateur, température fraîche',
              'Évitez les activités stimulantes après 20h',
            ],
          ));
        }
      }
    }

    return advice;
  }

  /// Conseils basés sur les triggers environnementaux
  Future<List<PreventionAdvice>> _getTriggerBasedAdvice(
    PatientRiskProfile profile,
  ) async {
    final advice = <PreventionAdvice>[];
    final envData = await _envService.getCurrentData();

    if (envData == null) return advice;

    for (var trigger in profile.triggers) {
      if (trigger.type == 'pollution' && envData.aqi > trigger.threshold) {
        advice.add(PreventionAdvice(
          title: '🚨 VOTRE facteur de risque détecté',
          message:
              'La pollution atteint ${envData.aqi}, ce qui déclenche '
              'une crise chez VOUS dans ${trigger.delayHours}h en moyenne.',
          timing: 'Dès maintenant',
          evidence:
              'Corrélation observée sur ${trigger.occurrences} événements similaires',
          actions: trigger.recommendedActions,
        ));
      }

      if (trigger.type == 'humidity' &&
          envData.humidity > trigger.threshold) {
        advice.add(PreventionAdvice(
          title: '💧 Humidité élevée - Votre trigger personnel',
          message:
              'Humidité: ${envData.humidity.toStringAsFixed(0)}%. '
              'Ce niveau déclenche habituellement des symptômes chez vous.',
          timing: 'Dans les ${trigger.delayHours}h',
          evidence:
              'Basé sur ${trigger.occurrences} occurrences précédentes',
          actions: trigger.recommendedActions,
        ));
      }
    }

    return advice;
  }

  /// Conseil basé sur l'anomalie personnelle
  PreventionAdvice? _getAnomalyBasedAdvice(
    PatientRiskProfile profile,
    HealthData currentData,
  ) {
    if (!profile.isAnomalousForThisPatient(
      currentData.spo2,
      currentData.breathingRate,
      currentData.pef,
    )) {
      return null;
    }

    final spo2Drop = profile.baselineSpo2 - currentData.spo2;
    final breathingIncrease =
        currentData.breathingRate - profile.baselineBreathingRate;

    return PreventionAdvice(
      title: '⚠️ Anomalie par rapport à VOTRE normale',
      message: 'Vos paramètres actuels s\'écartent de votre baseline:\n'
          '${spo2Drop > 2 ? '• SpO₂: ${currentData.spo2}% (votre normale: ${profile.baselineSpo2.toStringAsFixed(1)}%)\n' : ''}'
          '${breathingIncrease > 4 ? '• Fréquence resp.: ${currentData.breathingRate} bpm (votre normale: ${profile.baselineBreathingRate} bpm)\n' : ''}'
          'Ceci est inhabituel POUR VOUS.',
      timing: 'Maintenant',
      evidence:
          'Baseline calculée sur ${profile.daysAnalyzed} jours d\'historique',
      actions: [
        'Identifiez si quelque chose a changé (environnement, traitement, activité)',
        'Reposez-vous 30 minutes et re-mesurez',
        'Si les valeurs ne s\'améliorent pas, contactez votre médecin',
        'Notez les circonstances pour ajuster votre profil',
      ],
    );
  }

  /// Conseil basé sur le risque horaire
  PreventionAdvice? _getTimeBasedAdvice(PatientRiskProfile profile) {
    final currentRisk = profile.getCurrentTimeRisk();

    if (currentRisk.riskScore < 50) return null;

    return PreventionAdvice(
      title: '⏰ Période à risque pour vous',
      message:
          'Vous entrez dans une période à risque élevé (${currentRisk.period}). '
          'Score de risque: ${currentRisk.riskScore.toStringAsFixed(0)}/100.',
      timing: 'Maintenant',
      evidence: currentRisk.description ?? 'Pattern identifié sur votre profil',
      actions: [
        'Évitez les efforts physiques intenses',
        'Gardez vos médicaments à portée de main',
        'Surveillez vos symptômes plus fréquemment',
        'Reposez-vous davantage pendant cette période',
      ],
    );
  }
}
