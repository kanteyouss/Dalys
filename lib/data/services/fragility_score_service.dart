import 'dart:math';
import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/fragility_models.dart';
import '../models/long_term_analysis_models.dart';
import '../models/fragility_forecast_models.dart';
import 'environmental_service.dart';
import 'trend_analysis_service.dart';
import '../../core/enums/app_enums.dart';

/// Service de calcul du score de fragilité
class FragilityScoreService {
  static final FragilityScoreService _instance =
      FragilityScoreService._internal();
  factory FragilityScoreService() => _instance;
  FragilityScoreService._internal();

  final EnvironmentalService _envService = EnvironmentalService();
  final TrendAnalysisService _trendService = TrendAnalysisService();

  /// Calcule le score de fragilité actuel (0-100)
  Future<FragilityScore> calculateCurrentFragility(
    List<HealthData> last14days,
    PatientRiskProfile profile,
  ) async {
    if (last14days.isEmpty) {
      return _getDefaultScore();
    }

    double score = 0;
    final factors = <RiskFactor>[];

    // FACTEUR PRIORITAIRE: Valeurs absolues critiques actuelles - 40 points max
    // Ce facteur doit être évalué EN PREMIER car il reflète l'état immédiat
    final criticalFactor = _analyzeCurrentCriticalValues(last14days.last);
    if (criticalFactor != null) {
      score += criticalFactor.contribution;
      factors.add(criticalFactor);
    }

    // Facteur 1: Variabilité des mesures (instabilité = risque) - 15 points max
    final variabilityFactor = _analyzeVariability(last14days);
    if (variabilityFactor != null) {
      score += variabilityFactor.contribution;
      factors.add(variabilityFactor);
    }

    // Facteur 2: Tendance négative persistante - 20 points max
    final trendFactor = await _analyzeTrend(last14days);
    if (trendFactor != null) {
      score += trendFactor.contribution;
      factors.add(trendFactor);
    }

    // Facteur 3: Fréquence des épisodes anormaux - 15 points max
    final episodeFactor = _analyzeEpisodeFrequency(last14days);
    if (episodeFactor != null) {
      score += episodeFactor.contribution;
      factors.add(episodeFactor);
    }

    // Facteur 4: Écart par rapport au profil personnel - 10 points max
    final personalFactor = _analyzePersonalDeviation(last14days, profile);
    if (personalFactor != null) {
      score += personalFactor.contribution;
      factors.add(personalFactor);
    }

    // Facteur 5: Contexte environnemental - 10 points max (inchangé)
    final envFactor = await _analyzeEnvironment();
    if (envFactor != null) {
      score += envFactor.contribution;
      factors.add(envFactor);
    }

    // Normalisation du score (max 100)
    score = score.clamp(0, 100);

    final level = _getFragilityLevel(score);
    final recommendations = _getFragilityRecommendations(score, factors);
    final nextReview = _calculateNextReviewDuration(score);

    return FragilityScore(
      value: score,
      level: level,
      factors: factors,
      nextReviewIn: nextReview,
      recommendations: recommendations,
    );
  }

  /// NOUVEAU: Calcul de prédictions multi-horizon basé sur TOUT l'historique
  Future<FragilityForecast> calculateFragilityForecast(
    List<HealthData> fullHistory,
    PatientRiskProfile profile,
  ) async {
    if (fullHistory.isEmpty) {
      return FragilityForecast.empty();
    }

    // Analyse long-terme avec tout l'historique
    final longTermAnalysis =
        await _trendService.analyzeLongTermTrends(fullHistory);

    // Score actuel (garde la logique existante)
    final currentScore = await calculateCurrentFragility(
      fullHistory.length > 14
          ? fullHistory.sublist(fullHistory.length - 14)
          : fullHistory,
      profile,
    );

    // Prédictions multi-horizon
    final forecast6h = await _predictFragility6Hours(fullHistory, profile);
    final forecast24h =
        await _predictFragility24Hours(fullHistory, profile, longTermAnalysis);
    final forecast7d =
        await _predictFragility7Days(fullHistory, profile, longTermAnalysis);

    // Recommandations préventives basées sur les prédictions
    final preventiveRecommendations = _generatePreventiveRecommendations(
      currentScore,
      forecast6h,
      forecast24h,
      forecast7d,
      longTermAnalysis,
    );

    return FragilityForecast(
      currentScore: currentScore,
      prediction6Hours: forecast6h,
      prediction24Hours: forecast24h,
      prediction7Days: forecast7d,
      longTermAnalysis: longTermAnalysis,
      preventiveRecommendations: preventiveRecommendations,
      confidence: _calculateForecastConfidence(fullHistory),
      generatedAt: DateTime.now(),
    );
  }

  /// Prédiction à 6 heures (court terme)
  Future<FragilityPrediction> _predictFragility6Hours(
    List<HealthData> history,
    PatientRiskProfile profile,
  ) async {
    final recent =
        history.length > 3 ? history.sublist(history.length - 3) : history;

    if (recent.isEmpty) {
      return FragilityPrediction.low(confidence: 0.0);
    }

    // Analyse de la tendance immédiate
    final spo2Values = recent.map((d) => d.spo2.toDouble()).toList();
    final trend = _calculateLinearTrend(spo2Values);
    final currentSpo2 = recent.last.spo2;

    // Prédiction basée sur la continuité de la tendance
    final predicted6h = currentSpo2 + (trend * 0.25); // 6h = 1/4 jour

    // Facteurs de risque 6h
    double riskScore = 0;
    final factors = <String>[];

    // Tendance critique immédiate
    if (trend < -2.0) {
      riskScore += 40;
      factors.add('Chute rapide SpO₂ en cours');
    }

    // Valeur prédite critique
    if (predicted6h < 90) {
      riskScore += 50;
      factors.add('SpO₂ prédite < 90% dans 6h');
    } else if (predicted6h < 95) {
      riskScore += 20;
      factors.add('SpO₂ prédite limite dans 6h');
    }

    // Instabilité récente
    final variance = _calculateVariance(spo2Values);
    if (variance > 9) {
      // Très instable
      riskScore += 15;
      factors.add('Instabilité élevée récente');
    }

    return FragilityPrediction(
      predictedScore: riskScore.clamp(0, 100),
      predictedLevel: _getFragilityLevel(riskScore),
      confidence: _calculateShortTermConfidence(recent),
      riskFactors: factors,
      timeHorizon: '6 heures',
      worstCaseScenario: riskScore > 40
          ? 'Sans action, le risque respiratoire devient élevé dans les 6 prochaines heures.'
          : 'Maintien de la stabilité actuelle prévu.',
    );
  }

  /// Prédiction à 24 heures (moyen terme)
  Future<FragilityPrediction> _predictFragility24Hours(
    List<HealthData> history,
    PatientRiskProfile profile,
    LongTermTrendAnalysis longTermAnalysis,
  ) async {
    if (history.isEmpty) {
      return FragilityPrediction.low(confidence: 0.0);
    }

    double riskScore = 0;
    final factors = <String>[];

    // Utiliser les patterns quotidiens détectés
    final currentHour = DateTime.now().hour;
    final dailyRisk = _predictDailyRisk(history, currentHour);
    riskScore += dailyRisk.score;
    if (dailyRisk.factor.isNotEmpty) factors.add(dailyRisk.factor);

    // Tendance long-terme
    if (!longTermAnalysis.hasInsufficientData) {
      final spo2Trend = longTermAnalysis.longTermTrends.spo2Trend;
      if (spo2Trend < -1.0) {
        riskScore += 25;
        factors.add('Déclin long-terme significatif');
      } else if (spo2Trend < -0.5) {
        riskScore += 15;
        factors.add('Déclin long-terme modéré');
      }
    }

    // Patterns hebdomadaires
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowWeekday = tomorrow.weekday;
    if (longTermAnalysis.weeklyPatterns.spo2ByDay
        .containsKey(tomorrowWeekday)) {
      final tomorrowAvg =
          longTermAnalysis.weeklyPatterns.spo2ByDay[tomorrowWeekday]!;
      final todayAvg = history.isNotEmpty ? history.last.spo2.toDouble() : 96.0;

      if (tomorrowAvg < todayAvg - 2) {
        riskScore += 10;
        factors.add('Pattern hebdomadaire défavorable demain');
      }
    }

    return FragilityPrediction(
      predictedScore: riskScore.clamp(0, 100),
      predictedLevel: _getFragilityLevel(riskScore),
      confidence: _calculateMediumTermConfidence(history, longTermAnalysis),
      riskFactors: factors,
      timeHorizon: '24 heures',
      worstCaseScenario: riskScore > 30
          ? 'Une dégradation progressive de votre état est possible d\'ici demain sans ajustement.'
          : 'Votre état devrait rester stable pour les prochaines 24 heures.',
    );
  }

  /// Prédiction à 7 jours (long terme)
  Future<FragilityPrediction> _predictFragility7Days(
    List<HealthData> history,
    PatientRiskProfile profile,
    LongTermTrendAnalysis longTermAnalysis,
  ) async {
    if (history.length < 7) {
      return FragilityPrediction.low(confidence: 0.0);
    }

    double riskScore = 0;
    final factors = <String>[];

    // Tendances long-terme dominantes pour prédiction 7j
    if (!longTermAnalysis.hasInsufficientData) {
      final trends = longTermAnalysis.longTermTrends;

      // Projection de la tendance SpO₂
      final weeklyTrendImpact = trends.spo2Trend * 7; // Impact sur 7 jours
      if (weeklyTrendImpact < -3.0) {
        riskScore += 40;
        factors.add('Projection dégradation significative');
      } else if (weeklyTrendImpact < -1.5) {
        riskScore += 25;
        factors.add('Projection dégradation modérée');
      }

      // Force de la tendance
      if (trends.trendStrength > 2.0) {
        riskScore += 15;
        factors.add('Tendance très marquée');
      }
    }

    // Cycles récurrents défavorables
    for (var cycle in longTermAnalysis.recurringCycles) {
      if (cycle.lengthDays <= 7 && cycle.similarity > 0.8) {
        if (cycle.pattern.contains('dégradation')) {
          riskScore += 20;
          factors.add('Cycle défavorable de ${cycle.lengthDays} jours détecté');
        }
      }
    }

    // Analyse des corrélations pour prédiction
    final correlations = longTermAnalysis.extendedCorrelations;
    if (correlations.spo2BreathingCorr.abs() > 0.7) {
      // Forte corrélation = prédictibilité mais aussi fragilité
      riskScore += 10;
      factors.add('Forte interdépendance des paramètres');
    }

    return FragilityPrediction(
      predictedScore: riskScore.clamp(0, 100),
      predictedLevel: _getFragilityLevel(riskScore),
      confidence: _calculateLongTermConfidence(history, longTermAnalysis),
      riskFactors: factors,
      timeHorizon: '7 jours',
      worstCaseScenario: riskScore > 25
          ? 'Une tendance à la fragilisation se dessine sur la semaine à venir.'
          : 'La tendance hebdomadaire reste favorable et stable.',
    );
  }

  /// Génère recommandations préventives basées sur toutes les prédictions
  List<PreventiveRecommendation> _generatePreventiveRecommendations(
    FragilityScore currentScore,
    FragilityPrediction forecast6h,
    FragilityPrediction forecast24h,
    FragilityPrediction forecast7d,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final recommendations = <PreventiveRecommendation>[];

    // Recommandations immédiates (6h)
    if (forecast6h.predictedLevel == FragilityLevel.critical) {
      recommendations.add(PreventiveRecommendation(
        priority: RecommendationPriority.urgent,
        timeframe: '6 heures',
        title: '🚨 Action immédiate requise',
        description: 'Risque critique détecté dans les 6h',
        actions: [
          'Surveiller SpO₂ toutes les 2 heures',
          'Éviter tout effort physique',
          'Préparer médicaments de secours',
          'Alerter contacts d\'urgence',
        ],
      ));
    }

    // Recommandations quotidiennes (24h)
    if (forecast24h.predictedLevel != FragilityLevel.stable) {
      recommendations.add(PreventiveRecommendation(
        priority: forecast24h.predictedLevel == FragilityLevel.critical
            ? RecommendationPriority.high
            : RecommendationPriority.medium,
        timeframe: '24 heures',
        title: 'Ajustements pour demain',
        description: 'Optimisation basée sur vos patterns personnels',
        actions: _getDailyPreventiveActions(forecast24h, longTermAnalysis),
      ));
    }

    // Recommandations hebdomadaires (7j)
    if (forecast7d.predictedLevel != FragilityLevel.stable) {
      recommendations.add(PreventiveRecommendation(
        priority: RecommendationPriority.medium,
        timeframe: '7 jours',
        title: 'Stratégie de la semaine',
        description: 'Plan basé sur vos cycles personnels',
        actions: _getWeeklyPreventiveActions(forecast7d, longTermAnalysis),
      ));
    }

    return recommendations;
  }

  /// NOUVEAU: Analyse les valeurs critiques actuelles
  /// C'est le facteur le plus important car il reflète l'état immédiat
  RiskFactor? _analyzeCurrentCriticalValues(HealthData current) {
    double contribution = 0;
    final List<String> issues = [];

    // SpO2 critique (< 90% = urgence médicale, < 95% = anormal)
    if (current.spo2 < 90) {
      contribution += 40; // Score maximum - urgence
      issues.add('SpO₂ CRITIQUE: ${current.spo2}% (< 90%)');
    } else if (current.spo2 < 92) {
      contribution += 30; // Très bas
      issues.add('SpO₂ très basse: ${current.spo2}% (< 92%)');
    } else if (current.spo2 < 95) {
      contribution += 20; // Anormal
      issues.add('SpO₂ anormale: ${current.spo2}% (< 95%)');
    }

    // Fréquence respiratoire anormale
    if (current.breathingRate > 25) {
      contribution += 25; // Tachypnée sévère
      issues.add('Tachypnée sévère: ${current.breathingRate} bpm (> 25)');
    } else if (current.breathingRate > 20) {
      contribution += 15; // Tachypnée modérée
      issues.add('Tachypnée: ${current.breathingRate} bpm (> 20)');
    } else if (current.breathingRate < 12) {
      contribution += 20; // Bradypnée
      issues.add('Bradypnée: ${current.breathingRate} bpm (< 12)');
    }

    // PEF très bas (obstruction bronchique)
    if (current.pef < 200) {
      contribution += 30; // Obstruction sévère
      issues.add('PEF critique: ${current.pef.toInt()} L/min (< 200)');
    } else if (current.pef < 300) {
      contribution += 20; // Obstruction modérée
      issues.add('PEF bas: ${current.pef.toInt()} L/min (< 300)');
    } else if (current.pef < 350) {
      contribution += 10; // Légèrement bas
      issues.add('PEF limite: ${current.pef.toInt()} L/min (< 350)');
    }

    // Plafonner la contribution à 40 points
    contribution = contribution.clamp(0, 40);

    if (issues.isEmpty) {
      return null;
    }

    return RiskFactor(
      name: 'Valeurs actuelles critiques',
      contribution: contribution,
      explanation: issues.first,
      evidence: issues.length > 1
          ? 'Problèmes détectés: ${issues.join(", ")}'
          : 'Valeur hors des normes de sécurité',
    );
  }

  /// Analyse la variabilité (instabilité) - max 15 points
  RiskFactor? _analyzeVariability(List<HealthData> history) {
    final spo2Values = history.map((d) => d.spo2.toDouble()).toList();
    final spo2Variability = _calculateStdDev(spo2Values);

    if (spo2Variability > 2.0) {
      // Seuil abaissé de 3.0 à 2.0
      final contribution = (spo2Variability * 5).clamp(0, 15).toDouble();
      return RiskFactor(
        name: 'Instabilité SpO₂',
        contribution: contribution,
        explanation:
            'Vos valeurs fluctuent beaucoup (écart-type: ${spo2Variability.toStringAsFixed(1)}%)',
        evidence:
            'Moyenne: ${_calculateMean(spo2Values).toStringAsFixed(1)}%, Écart-type: ${spo2Variability.toStringAsFixed(1)}%',
      );
    }

    return null;
  }

  /// Analyse les tendances négatives - max 20 points
  Future<RiskFactor?> _analyzeTrend(List<HealthData> history) async {
    if (history.length < 3) return null; // Réduit de 7 à 3 jours minimum

    final recentData =
        history.length >= 7 ? history.sublist(history.length - 7) : history;
    final trendAlerts = await _trendService.detectDangerousTrends(recentData);

    // Compter les alertes de tendance à haute sévérité
    final highSeverityAlerts =
        trendAlerts.where((a) => a.severity == 'high').length;
    final mediumSeverityAlerts =
        trendAlerts.where((a) => a.severity == 'medium').length;

    if (highSeverityAlerts > 0 || mediumSeverityAlerts > 0) {
      final contribution =
          (highSeverityAlerts * 12.0 + mediumSeverityAlerts * 8.0)
              .clamp(0.0, 20.0);

      return RiskFactor(
        name: 'Déclin progressif',
        contribution: contribution,
        explanation: 'Tendance à la baisse détectée',
        evidence:
            '$highSeverityAlerts alerte(s) haute sévérité, $mediumSeverityAlerts alerte(s) moyenne sévérité',
      );
    }

    return null;
  }

  /// Analyse la fréquence des épisodes anormaux - max 15 points
  RiskFactor? _analyzeEpisodeFrequency(List<HealthData> history) {
    final abnormalDays = history.where((d) => d.hasAnyAbnormalValue).length;
    final totalDays = history.length;
    final percentage = (abnormalDays / totalDays * 100);

    if (abnormalDays > 0) {
      // Maintenant on compte même un seul épisode
      // Contribution progressive: 1 épisode = 5 points, augmente avec la fréquence
      final contribution =
          (percentage * 0.3 + abnormalDays * 2).clamp(0.0, 15.0);

      return RiskFactor(
        name: 'Fréquence épisodes',
        contribution: contribution,
        explanation:
            '$abnormalDays mesure(s) anormale(s) sur $totalDays (${percentage.toStringAsFixed(0)}%)',
        evidence: 'Valeurs hors normes détectées dans l\'historique récent',
      );
    }

    return null;
  }

  /// Analyse l'écart par rapport au profil personnel - max 10 points
  RiskFactor? _analyzePersonalDeviation(
    List<HealthData> history,
    PatientRiskProfile profile,
  ) {
    final currentData = history.last;

    if (profile.isAnomalousForThisPatient(
      currentData.spo2,
      currentData.breathingRate,
      currentData.pef,
    )) {
      final spo2Drop = profile.baselineSpo2 - currentData.spo2;
      final contribution = (spo2Drop * 3).clamp(0, 10).toDouble();

      return RiskFactor(
        name: 'Anomalie personnelle',
        contribution: contribution,
        explanation: 'Valeurs inhabituelles vs votre baseline',
        evidence:
            'SpO₂: ${currentData.spo2}% (baseline: ${profile.baselineSpo2.toStringAsFixed(1)}%)',
      );
    }

    return null;
  }

  /// Analyse l'environnement
  Future<RiskFactor?> _analyzeEnvironment() async {
    final envData = await _envService.getCurrentData();

    if (envData == null) return null;

    if (envData.aqi > 100) {
      final contribution =
          ((envData.aqi.toDouble() - 100.0) / 10.0).clamp(0.0, 10.0);

      return RiskFactor(
        name: 'Environnement défavorable',
        contribution: contribution,
        explanation: 'Pollution élevée (AQI: ${envData.aqi.toInt()})',
        evidence: 'Qualité air: ${_envService.getAqiRiskLevel(envData.aqi)}',
      );
    }

    if (envData.humidity > 70) {
      return RiskFactor(
        name: 'Humidité excessive',
        contribution: 5,
        explanation:
            'Humidité élevée (${envData.humidity.toStringAsFixed(0)}%)',
        evidence: 'Risque de moisissures et difficultés respiratoires',
      );
    }

    return null;
  }

  /// Détermine le niveau de fragilité
  FragilityLevel _getFragilityLevel(double score) {
    if (score >= 70) return FragilityLevel.critical;
    if (score >= 40) return FragilityLevel.elevated;
    if (score >= 20) return FragilityLevel.moderate;
    return FragilityLevel.stable;
  }

  /// Génère les recommandations selon le score
  List<String> _getFragilityRecommendations(
    double score,
    List<RiskFactor> factors,
  ) {
    if (score >= 70) {
      return [
        '🚨 PHASE PRÉ-CRISE : Contactez votre médecin AUJOURD\'HUI',
        'Évitez TOUTE activité physique',
        'Mesurez vos paramètres toutes les 4 heures',
        'Préparez votre plan d\'urgence (médicaments, contacts)',
        'Ne restez pas seul(e) si possible',
      ];
    } else if (score >= 40) {
      return [
        '⚠️ SURVEILLANCE RENFORCÉE : Consultez cette semaine',
        'Limitez les efforts physiques',
        'Mesurez 2x par jour (matin + soir)',
        'Évitez les zones polluées et allergènes',
        'Gardez vos médicaments de secours à portée',
      ];
    } else if (score >= 20) {
      return [
        '📊 VIGILANCE NORMALE : Continuez votre suivi',
        'Maintenez vos mesures quotidiennes',
        'Pratiquez vos exercices respiratoires',
        'Respectez votre traitement',
        'Notez tout changement inhabituel',
      ];
    } else {
      return [
        '✅ ÉTAT STABLE : Continuez vos bonnes habitudes',
        'Mesure tous les 2 jours suffisante',
        'Maintenez votre activité physique légère',
        'Aérez régulièrement votre logement',
        'Profitez de votre stabilité !',
      ];
    }
  }

  /// Calcule la durée avant la prochaine évaluation
  Duration _calculateNextReviewDuration(double score) {
    if (score >= 70) return Duration(hours: 4); // Toutes les 4h
    if (score >= 40) return Duration(hours: 12); // 2x par jour
    if (score >= 20) return Duration(days: 1); // 1x par jour
    return Duration(days: 2); // Tous les 2 jours
  }

  /// Score par défaut (pas assez de données)
  FragilityScore _getDefaultScore() {
    return FragilityScore(
      value: 25,
      level: FragilityLevel.moderate,
      factors: [
        RiskFactor(
          name: 'Données insuffisantes',
          contribution: 25,
          explanation: 'Pas assez d\'historique pour analyse complète',
          evidence: 'Continuez à enregistrer vos mesures',
        ),
      ],
      nextReviewIn: Duration(days: 1),
      recommendations: [
        '📊 Enregistrez vos mesures quotidiennement',
        'Après 7 jours, l\'analyse sera plus précise',
        'Notez vos symptômes et activités',
      ],
    );
  }

  /// Calcule la moyenne
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calcule l'écart-type
  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = _calculateMean(values);
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;

    return sqrt(variance);
  }

  // NOUVELLES MÉTHODES UTILITAIRES POUR PRÉDICTIONS MULTI-HORIZON

  double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    final n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumXX += i * i;
    }

    final denominator = n * sumXX - sumX * sumX;
    if (denominator == 0) return 0.0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquaredDiffs =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return sumSquaredDiffs / (values.length - 1);
  }

  double _calculateShortTermConfidence(List<HealthData> recent) {
    if (recent.length < 2) return 0.5;

    final spo2Values = recent.map((d) => d.spo2.toDouble()).toList();
    final variance = _calculateVariance(spo2Values);

    // Plus la variance est faible, plus on est confiant dans la prédiction court-terme
    return max(0.3, min(0.95, 1.0 - (variance / 50.0)));
  }

  double _calculateMediumTermConfidence(
      List<HealthData> history, LongTermTrendAnalysis analysis) {
    if (history.length < 7) return 0.3;

    // Confiance basée sur la quantité de données et la consistance des patterns
    final dataFactor =
        min(history.length / 30.0, 1.0); // Plus de données = plus de confiance
    final patternFactor = analysis.hasInsufficientData ? 0.2 : 0.8;

    return (dataFactor + patternFactor) / 2.0;
  }

  double _calculateLongTermConfidence(
      List<HealthData> history, LongTermTrendAnalysis analysis) {
    if (history.length < 14) return 0.2;

    // Confiance long-terme nécessite beaucoup de données et des patterns clairs
    final dataFactor = min(history.length / 60.0, 1.0); // Optimal à 60+ jours
    final trendStrength = analysis.hasInsufficientData
        ? 0.1
        : min(analysis.longTermTrends.trendStrength / 5.0, 1.0);
    final cycleFactor = analysis.recurringCycles.isEmpty ? 0.3 : 0.8;

    return (dataFactor + trendStrength + cycleFactor) / 3.0;
  }

  double _calculateForecastConfidence(List<HealthData> fullHistory) {
    if (fullHistory.length < 7) return 0.3;

    // Confiance globale basée sur la richesse des données
    final dataRichness = min(fullHistory.length / 50.0, 1.0);
    final timeSpan = fullHistory.isNotEmpty
        ? DateTime.now().difference(fullHistory.first.date).inDays / 30.0
        : 0.0; // Mois de données
    final timeSpanFactor = min(timeSpan, 1.0);

    return (dataRichness + timeSpanFactor) / 2.0;
  }

  DailyRiskFactor _predictDailyRisk(List<HealthData> history, int currentHour) {
    if (history.isEmpty) return DailyRiskFactor.none();

    // Analyser les patterns horaires dans l'historique
    final hourlyData = <int, List<double>>{};

    for (var data in history) {
      final hour = data.date.hour;
      hourlyData.putIfAbsent(hour, () => []).add(data.spo2.toDouble());
    }

    // Prédire le risque pour l'heure actuelle + 24h
    final targetHour = (currentHour + 24) % 24;

    if (hourlyData.containsKey(targetHour) &&
        hourlyData[targetHour]!.isNotEmpty) {
      final avgSpo2AtHour = hourlyData[targetHour]!.reduce((a, b) => a + b) /
          hourlyData[targetHour]!.length;
      final currentSpo2 = history.last.spo2.toDouble();

      if (avgSpo2AtHour < currentSpo2 - 2) {
        return DailyRiskFactor(
          score: 15.0,
          factor: 'Pattern horaire défavorable à ${targetHour}h',
        );
      }
    }

    return DailyRiskFactor.none();
  }

  List<String> _getDailyPreventiveActions(
    FragilityPrediction forecast24h,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final actions = <String>[];

    // Actions basées sur le niveau de risque prédit
    switch (forecast24h.predictedLevel) {
      case FragilityLevel.critical:
        actions.addAll([
          'Planifier repos complet demain',
          'Mesures toutes les 4h',
          'Éviter sorties non essentielles',
          'Préparer médicaments d\'urgence',
        ]);
        break;
      case FragilityLevel.elevated:
        actions.addAll([
          'Limiter activités physiques',
          'Mesures 3x par jour',
          'Aération fréquente du logement',
          'Éviter zones polluées',
        ]);
        break;
      case FragilityLevel.moderate:
        actions.addAll([
          'Maintenir routine légère',
          'Mesures 2x par jour',
          'Exercices respiratoires',
        ]);
        break;
      case FragilityLevel.stable:
        actions.addAll([
          'Continuer activités normales',
          'Mesure quotidienne suffisante',
        ]);
        break;
    }

    // Actions spécifiques aux patterns détectés
    if (!longTermAnalysis.hasInsufficientData) {
      final bestDay = longTermAnalysis.weeklyPatterns.bestDayName;
      final worstDay = longTermAnalysis.weeklyPatterns.worstDayName;

      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowName = _getDayName(tomorrow.weekday);

      if (tomorrowName == worstDay) {
        actions.add('⚠️ Votre jour le plus difficile: vigilance renforcée');
      } else if (tomorrowName == bestDay) {
        actions.add('✅ Votre meilleur jour: profitez-en pour récupérer');
      }
    }

    return actions;
  }

  List<String> _getWeeklyPreventiveActions(
    FragilityPrediction forecast7d,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final actions = <String>[];

    // Actions basées sur les cycles récurrents
    for (var cycle in longTermAnalysis.recurringCycles) {
      if (cycle.lengthDays == 7) {
        actions.add(
            'Cycle hebdomadaire détecté: adapter routine les ${cycle.pattern}');
      }
    }

    // Actions basées sur les corrélations
    final correlations = longTermAnalysis.extendedCorrelations;
    if (correlations.spo2BreathingCorr.abs() > 0.6) {
      actions.add(
          'Forte corrélation respiration-SpO₂: privilégier exercices respiratoires');
    }

    // Actions préventives générales
    if (forecast7d.predictedLevel != FragilityLevel.stable) {
      actions.addAll([
        'Planifier rdv médecin cette semaine',
        'Revoir plan de traitement',
        'Optimiser environnement (humidité, température)',
        'Renforcer soutien social',
      ]);
    }

    return actions;
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return weekday >= 1 && weekday <= 7 ? days[weekday] : 'Inconnu';
  }
}
