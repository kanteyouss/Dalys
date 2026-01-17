import 'dart:math';
import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/fragility_models.dart';
import 'environmental_service.dart';
import 'trend_analysis_service.dart';

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

    if (spo2Variability > 2.0) {  // Seuil abaissé de 3.0 à 2.0
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
    if (history.length < 3) return null;  // Réduit de 7 à 3 jours minimum

    final recentData = history.length >= 7 
        ? history.sublist(history.length - 7) 
        : history;
    final trendAlerts = await _trendService.detectDangerousTrends(recentData);

    // Compter les alertes de tendance à haute sévérité
    final highSeverityAlerts =
        trendAlerts.where((a) => a.severity == 'high').length;
    final mediumSeverityAlerts =
        trendAlerts.where((a) => a.severity == 'medium').length;

    if (highSeverityAlerts > 0 || mediumSeverityAlerts > 0) {
      final contribution = (highSeverityAlerts * 12.0 + mediumSeverityAlerts * 8.0)
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

    if (abnormalDays > 0) {  // Maintenant on compte même un seul épisode
      // Contribution progressive: 1 épisode = 5 points, augmente avec la fréquence
      final contribution = (percentage * 0.3 + abnormalDays * 2).clamp(0.0, 15.0);

      return RiskFactor(
        name: 'Fréquence épisodes',
        contribution: contribution,
        explanation:
            '$abnormalDays mesure(s) anormale(s) sur $totalDays (${percentage.toStringAsFixed(0)}%)',
        evidence:
            'Valeurs hors normes détectées dans l\'historique récent',
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
      final contribution = ((envData.aqi.toDouble() - 100.0) / 10.0).clamp(0.0, 10.0);

      return RiskFactor(
        name: 'Environnement défavorable',
        contribution: contribution,
        explanation: 'Pollution élevée (AQI: ${envData.aqi.toInt()})',
        evidence:
            'Qualité air: ${_envService.getAqiRiskLevel(envData.aqi)}',
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
    final variance = values
            .map((v) => pow(v - mean, 2))
            .reduce((a, b) => a + b) /
        values.length;

    return sqrt(variance);
  }
}
