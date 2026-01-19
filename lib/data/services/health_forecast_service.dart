import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/fragility_forecast_models.dart';
import '../models/long_term_analysis_models.dart';
import '../models/comprehensive_forecast_models.dart';
import 'trend_analysis_service.dart';
import 'fragility_score_service.dart';
import 'predictive_alert_engine.dart';
import 'database_service.dart';

/// Service de prévisions avancées exploitant TOUTES les données historiques
/// Orchestrateur principal pour l'analyse prédictive complète
class HealthForecastService {
  static final HealthForecastService _instance = HealthForecastService._internal();
  factory HealthForecastService() => _instance;
  HealthForecastService._internal();

  final TrendAnalysisService _trendService = TrendAnalysisService();
  final FragilityScoreService _fragilityService = FragilityScoreService();
  final PredictiveAlertEngine _alertEngine = PredictiveAlertEngine();
  final DatabaseService _dbService = DatabaseService();

  /// Génère une prévision complète exploitant TOUT l'historique utilisateur
  /// Utilise les 80+ mesures disponibles pour des insights approfondis
  Future<ComprehensiveHealthForecast> generateComprehensiveForecast(int userId) async {
    // 1️⃣ Récupérer TOUT l'historique de l'utilisateur
    final fullHistory = await _getCompleteUserHistory(userId);
    
    if (fullHistory.isEmpty) {
      return ComprehensiveHealthForecast.empty();
    }

    // 2️⃣ Profil de risque du patient
    final profile = await _getOrCreatePatientProfile(userId);

    // 3️⃣ Analyse long-terme avec tout l'historique
    final longTermAnalysis = await _trendService.analyzeLongTermTrends(fullHistory);

    // 4️⃣ Prévisions de fragilité multi-horizon
    final fragilityForecast = await _fragilityService.calculateFragilityForecast(
      fullHistory,
      profile,
    );

    // 5️⃣ Alertes préventives multi-temporelles
    final multiHorizonAlerts = await _alertEngine.generateMultiHorizonAlerts(
      profile,
      fullHistory,
    );

    // 6️⃣ Insights personnalisés basés sur l'historique complet
    final personalizedInsights = _generatePersonalizedInsights(
      fullHistory,
      longTermAnalysis,
      fragilityForecast,
    );

    // 7️⃣ Score de santé global et évolution
    final healthScore = _calculateGlobalHealthScore(
      fullHistory,
      fragilityForecast,
      longTermAnalysis,
    );

    return ComprehensiveHealthForecast(
      userId: userId,
      dataPoints: fullHistory.length,
      timeSpan: _calculateTimeSpan(fullHistory),
      primaryTrigger: _identifyPrimaryTrigger(longTermAnalysis, fragilityForecast),
      confidenceReason: _buildConfidenceReason(fullHistory, longTermAnalysis),
      personalNormComparison: _buildPersonalNormComparison(longTermAnalysis),
      longTermAnalysis: longTermAnalysis,
      fragilityForecast: fragilityForecast,
      multiHorizonAlerts: multiHorizonAlerts,
      personalizedInsights: personalizedInsights,
      globalHealthScore: healthScore,
      confidence: _calculateOverallConfidence(fullHistory, longTermAnalysis),
      generatedAt: DateTime.now(),
      validUntil: DateTime.now().add(Duration(hours: 6)), // Mise à jour toutes les 6h
    );
  }

  /// Récupère TOUT l'historique utilisateur (pas de limite temporelle)
  Future<List<HealthData>> _getCompleteUserHistory(int userId) async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'health_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC', // Chronologique pour analyse temporelle
      // Pas de limite - on veut TOUTES les données
    );

    return results.map((row) => HealthData.fromJson({
      'user_id': row['user_id'],
      'date': row['date'],
      'spo2': row['spo2'],
      'breathing_rate': row['breathing_rate'],
      'pef': row['pef'],
      'temperature': row['temperature'],
      'humidity': row['humidity'],
      'env_temperature': row['env_temperature'],
      'symptoms': (row['symptoms'] as String?)?.isEmpty ?? true
          ? <String>[]
          : (row['symptoms'] as String).split(','),
      'risk_level': row['risk_level'],
    })).toList();
  }

  /// Récupère ou crée le profil patient
  Future<PatientRiskProfile> _getOrCreatePatientProfile(int userId) async {
    try {
      final db = await _dbService.database;
      final results = await db.query(
        'patient_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isNotEmpty) {
        return PatientRiskProfile.fromJson(results.first);
      }
    } catch (e) {
      // Table peut ne pas exister encore
    }

    // Créer profil par défaut
    return PatientRiskProfile.createDefault(userId);
  }

  /// Génère des insights personnalisés basés sur l'historique complet
  PersonalizedHealthInsights _generatePersonalizedInsights(
    List<HealthData> fullHistory,
    LongTermTrendAnalysis longTermAnalysis,
    FragilityForecast fragilityForecast,
  ) {
    final insights = <HealthInsight>[];

    // 📊 Insight sur la quantité de données
    insights.add(HealthInsight(
      category: 'Données',
      title: 'Richesse de votre historique',
      description: 'Vous avez ${fullHistory.length} mesures sur ${_calculateTimeSpan(fullHistory)}',
      significance: _calculateDataRichness(fullHistory),
      actionable: fullHistory.length < 30,
      action: fullHistory.length < 30 
          ? 'Continuez vos mesures régulières pour des prédictions plus précises'
          : null,
    ));

    // 📈 Insights sur les tendances long-terme
    if (!longTermAnalysis.hasInsufficientData) {
      final trends = longTermAnalysis.longTermTrends;
      
      if (trends.spo2Trend.abs() > 0.5) {
        insights.add(HealthInsight(
          category: 'Évolution',
          title: trends.spo2Trend > 0 ? 'Amélioration détectée' : 'Déclin détecté',
          description: 'SpO₂ ${trends.spo2Trend > 0 ? "s'améliore" : "décline"} de ${trends.spo2Trend.abs().toStringAsFixed(1)}%/semaine',
          significance: trends.trendStrength,
          actionable: trends.spo2Trend < 0,
          action: trends.spo2Trend < 0 
              ? 'Discuter de cette tendance avec votre médecin'
              : null,
        ));
      }

      // Insights sur les patterns hebdomadaires
      final weeklyPattern = longTermAnalysis.weeklyPatterns;
      if (weeklyPattern.spo2ByDay.isNotEmpty) {
        final bestDay = weeklyPattern.bestDayName;
        final worstDay = weeklyPattern.worstDayName;
        
        insights.add(HealthInsight(
          category: 'Patterns',
          title: 'Votre rythme hebdomadaire',
          description: 'Meilleur jour: $bestDay, Plus difficile: $worstDay',
          significance: 0.7,
          actionable: true,
          action: 'Planifiez activités importantes les $bestDay, repos les $worstDay',
        ));
      }

      // Insights sur les corrélations
      final correlations = longTermAnalysis.extendedCorrelations;
      if (correlations.spo2BreathingCorr.abs() > 0.6) {
        insights.add(HealthInsight(
          category: 'Corrélations',
          title: 'Lien SpO₂-Respiration fort',
          description: 'Vos paramètres sont ${correlations.spo2BreathingCorr > 0 ? "très" : "inversement"} liés',
          significance: correlations.spo2BreathingCorr.abs(),
          actionable: true,
          action: 'Les exercices respiratoires auront un impact direct sur votre SpO₂',
        ));
      }
    }

    // 🔮 Insights sur les prédictions
    if (fragilityForecast.prediction7Days.confidence > 0.6) {
      insights.add(HealthInsight(
        category: 'Prévision',
        title: 'Prédiction 7 jours fiable',
        description: 'Confiance ${fragilityForecast.prediction7Days.confidenceDescription} dans nos prédictions',
        significance: fragilityForecast.prediction7Days.confidence,
        actionable: fragilityForecast.prediction7Days.predictedLevel != fragilityForecast.currentScore.level,
        action: fragilityForecast.prediction7Days.predictedLevel != fragilityForecast.currentScore.level
            ? 'Suivre les recommandations préventives'
            : null,
      ));
    }

    return PersonalizedHealthInsights(
      insights: insights,
      overallPersonalizationScore: _calculatePersonalizationScore(fullHistory),
      dataQualityScore: _calculateDataQuality(fullHistory),
    );
  }

  /// Calcule un score de santé global basé sur toutes les analyses
  GlobalHealthScore _calculateGlobalHealthScore(
    List<HealthData> fullHistory,
    FragilityForecast fragilityForecast,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    double score = 50; // Baseline neutre

    // 1️⃣ Impact du score de fragilité actuel
    final currentFragility = fragilityForecast.currentScore.value;
    score += (100 - currentFragility) * 0.3; // 30% du poids

    // 2️⃣ Impact des tendances long-terme
    if (!longTermAnalysis.hasInsufficientData) {
      final spo2Trend = longTermAnalysis.longTermTrends.spo2Trend;
      score += spo2Trend * 10; // Positive trend = bonus, negative = malus
    }

    // 3️⃣ Impact de la stabilité (moins de variabilité = meilleur)
    if (fullHistory.length > 7) {
      final recent7 = fullHistory.sublist(fullHistory.length - 7);
      final spo2Values = recent7.map((d) => d.spo2.toDouble()).toList();
      final variance = _calculateVariance(spo2Values);
      score += (10 - variance.toDouble()) * 2; // Stabilité bonus
    }

    // 4️⃣ Impact du pronostic (prédictions favorables = bonus)
    final avgPrediction = (
      fragilityForecast.prediction6Hours.predictedScore +
      fragilityForecast.prediction24Hours.predictedScore +
      fragilityForecast.prediction7Days.predictedScore
    ) / 3;
    score += (100 - avgPrediction.toDouble()) * 0.2; // 20% du poids

    final double finalScore = score.clamp(0.0, 100.0).toDouble();

    return GlobalHealthScore(
      value: finalScore,
      level: _getHealthScoreLevel(finalScore),
      components: {
        'Fragilité actuelle': fragilityForecast.currentScore.value,
        'Tendance long-terme': longTermAnalysis.hasInsufficientData ? null : longTermAnalysis.longTermTrends.spo2Trend * 10 + 50,
        'Stabilité récente': fullHistory.length > 7 ? _calculateStability(fullHistory) : null,
        'Pronostic': avgPrediction,
      },
      interpretation: _getScoreInterpretation(finalScore),
    );
  }

  // MÉTHODES UTILITAIRES

  Duration _calculateTimeSpan(List<HealthData> history) {
    if (history.isEmpty) return const Duration(milliseconds: 0);
    return history.last.date.difference(history.first.date);
  }

  double _calculateOverallConfidence(List<HealthData> history, LongTermTrendAnalysis analysis) {
    if (history.isEmpty) return 0.0;
    
    final dataFactor = (history.length / 50.0).clamp(0.0, 1.0); // Optimal à 50+ points
    final timeFactor = (_calculateTimeSpan(history).inDays / 30.0).clamp(0.0, 1.0); // Optimal à 30+ jours
    final analysisFactor = analysis.hasInsufficientData ? 0.2 : 0.8;
    
    return (dataFactor + timeFactor + analysisFactor) / 3.0;
  }

  double _calculateDataRichness(List<HealthData> history) {
    if (history.isEmpty) return 0.0;
    
    final points = history.length;
    final timeSpan = _calculateTimeSpan(history).inDays;
    
    if (timeSpan == 0) return points > 10 ? 0.8 : 0.3;
    
    final density = points / timeSpan; // Mesures par jour
    return (density / 5.0).clamp(0.0, 1.0); // Optimal à 5+ mesures/jour
  }

  double _calculatePersonalizationScore(List<HealthData> history) {
    // Plus on a de données, plus on peut personnaliser
    return (history.length / 100.0).clamp(0.0, 1.0);
  }

  double _calculateDataQuality(List<HealthData> history) {
    if (history.isEmpty) return 0.0;
    
    // Vérifier la consistance et la complétude
    final completeEntries = history.where((d) => 
        d.spo2 > 0 && d.breathingRate > 0 && d.pef > 0).length;
    
    return completeEntries / history.length;
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquaredDiffs = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return sumSquaredDiffs / (values.length - 1);
  }

  double _calculateStability(List<HealthData> history) {
    final recent = history.length > 7 ? history.sublist(history.length - 7) : history;
    final spo2Values = recent.map((d) => d.spo2.toDouble()).toList();
    final variance = _calculateVariance(spo2Values);
    
    return (100 - variance * 5).clamp(0, 100); // Moins de variance = plus stable
  }

  HealthScoreLevel _getHealthScoreLevel(double score) {
    if (score >= 80) return HealthScoreLevel.excellent;
    if (score >= 65) return HealthScoreLevel.good;
    if (score >= 50) return HealthScoreLevel.fair;
    if (score >= 35) return HealthScoreLevel.poor;
    return HealthScoreLevel.critical;
  }

  String _getScoreInterpretation(double score) {
    if (score >= 80) return 'État de santé excellent avec pronostic très favorable';
    if (score >= 65) return 'Bonne santé générale avec quelques points d\'attention';
    if (score >= 50) return 'État stable nécessitant une surveillance régulière';
    if (score >= 35) return 'Situation préoccupante nécessitant des ajustements';
    return 'État critique nécessitant une intervention médicale urgente';
  }

  /// Identifie la cause principale de la tendance actuelle
  String _identifyPrimaryTrigger(
    LongTermTrendAnalysis longTermAnalysis,
    FragilityForecast fragilityForecast,
  ) {
    if (longTermAnalysis.hasInsufficientData) {
      return 'Données insuffisantes pour identifier une tendance';
    }

    // Analyser les tendances long-terme
    final spo2Trend = longTermAnalysis.longTermTrends.spo2Trend;
    final breathingTrend = longTermAnalysis.longTermTrends.breathingTrend;
    final pefTrend = longTermAnalysis.longTermTrends.pefTrend;

    if (spo2Trend < -0.5) {
      return 'Déclin progressif de la saturation en oxygène (SpO2)';
    }
    if (breathingTrend > 0.5) {
      return 'Augmentation de la fréquence respiratoire';
    }
    if (pefTrend < -0.3) {
      return 'Diminution du débit expiratoire de pointe (PEF)';
    }
    if (fragilityForecast.currentScore.value > 70) {
      return 'Score de fragilité élevé détecté';
    }

    return 'Paramètres stables dans l\'ensemble';
  }

  /// Construit la raison de la confiance dans la prévision
  String _buildConfidenceReason(
    List<HealthData> fullHistory,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    if (fullHistory.length < 10) {
      return 'Données insuffisantes (moins de 10 mesures)';
    }
    if (longTermAnalysis.hasInsufficientData) {
      return 'Historique trop court pour des tendances fiables';
    }

    final days = _calculateTimeSpan(fullHistory).inDays;
    final dataPoints = fullHistory.length;
    final trendStrength = longTermAnalysis.longTermTrends.trendStrength;

    if (days >= 30 && dataPoints >= 50 && trendStrength > 0.7) {
      return 'Prévision très fiable: $dataPoints mesures sur $days jours avec tendances claires';
    }
    if (days >= 14 && dataPoints >= 20) {
      return 'Prévision fiable: historique suffisant ($dataPoints mesures sur $days jours)';
    }
    if (days >= 7) {
      return 'Prévision modérée: historique court mais utilisable';
    }

    return 'Confiance limitée: continuez vos mesures régulières';
  }

  /// Compare les valeurs actuelles aux normes personnelles
  String _buildPersonalNormComparison(LongTermTrendAnalysis longTermAnalysis) {
    if (longTermAnalysis.hasInsufficientData) {
      return 'Établissement de vos normes personnelles en cours';
    }

    final spo2Trend = longTermAnalysis.longTermTrends.spo2TrendDescription;
    
    return 'Tendance SpO2: $spo2Trend par rapport à votre moyenne habituelle';
  }
}