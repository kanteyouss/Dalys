import 'dart:math' as math;
import '../models/health_data.dart';
import '../models/trend_models.dart';
import '../models/long_term_analysis_models.dart';
import '../../core/enums/app_enums.dart';

/// Service d'analyse de tendances pour la prédiction précoce
class TrendAnalysisService {
  static final TrendAnalysisService _instance =
      TrendAnalysisService._internal();
  factory TrendAnalysisService() => _instance;
  TrendAnalysisService._internal();

  /// Détecte les tendances dangereuses AVANT qu'elles deviennent critiques
  Future<List<TrendAlert>> detectDangerousTrends(
    List<HealthData> historique7jours,
  ) async {
    if (historique7jours.length < 3) {
      return []; // Pas assez de données pour analyse de tendance
    }

    final alerts = <TrendAlert>[];

    // 1️⃣ TENDANCE SPO2 : Déclin progressif
    final spo2Alerts = _analyzeSpo2Trend(historique7jours);
    alerts.addAll(spo2Alerts);

    // 2️⃣ TENDANCE FRÉQUENCE RESPIRATOIRE : Augmentation progressive
    final breathingAlerts = _analyzeBreathingRateTrend(historique7jours);
    alerts.addAll(breathingAlerts);

    // 3️⃣ TENDANCE PEF : Déclin du débit de pointe
    final pefAlerts = _analyzePefTrend(historique7jours);
    alerts.addAll(pefAlerts);

    // 4️⃣ PATTERN HORAIRE : Détérioration à certaines heures
    final timePatterns = _detectTimePatterns(historique7jours);
    alerts.addAll(timePatterns);

    // 5️⃣ CORRÉLATION MULTI-PARAMÈTRES
    final correlationAlerts = _detectCorrelatedDecline(historique7jours);
    alerts.addAll(correlationAlerts);

    // 6️⃣ VARIABILITÉ EXCESSIVE (instabilité = risque)
    final variabilityAlerts = _detectExcessiveVariability(historique7jours);
    alerts.addAll(variabilityAlerts);

    return alerts;
  }

  /// NOUVEAU: Analyse long-terme utilisant TOUT l'historique
  Future<LongTermTrendAnalysis> analyzeLongTermTrends(
    List<HealthData> fullHistory,
  ) async {
    if (fullHistory.length < 14) {
      return LongTermTrendAnalysis.insufficient();
    }
    // Calculer toutes les composantes d'analyse
    final seasonalPatterns = fullHistory.length >= 30
        ? _detectSeasonalPatterns(fullHistory)
        : <SeasonalPattern>[];

    final longTermTrends = _calculateLongTermTrends(fullHistory);
    final recurringCycles = _identifyRecurringCycles(fullHistory);
    final weeklyPatterns = _analyzeWeeklyPatterns(fullHistory);
    final extendedCorrelations = _calculateExtendedCorrelations(fullHistory);
    final riskPredictions = _generateRiskPredictions(fullHistory);

    return LongTermTrendAnalysis(
      seasonalPatterns: seasonalPatterns,
      longTermTrends: longTermTrends,
      recurringCycles: recurringCycles,
      weeklyPatterns: weeklyPatterns,
      extendedCorrelations: extendedCorrelations,
      riskPredictions: riskPredictions,
    );
  }

  /// NOUVEAU: Détecte patterns saisonniers sur 30+ jours
  List<SeasonalPattern> _detectSeasonalPatterns(List<HealthData> history) {
    final patterns = <SeasonalPattern>[];
    
    // Grouper par jour de la semaine
    final dayGroups = <int, List<HealthData>>{};
    for (var data in history) {
      final weekday = data.date.weekday;
      dayGroups.putIfAbsent(weekday, () => []).add(data);
    }

    // Analyser chaque jour de la semaine
    for (var entry in dayGroups.entries) {
      final dayData = entry.value;
      if (dayData.length >= 4) { // Au moins 4 occurrences
        final avgSpo2 = dayData.map((d) => d.spo2).reduce((a, b) => a + b) / dayData.length;
        final avgBreathing = dayData.map((d) => d.breathingRate).reduce((a, b) => a + b) / dayData.length;
        
        patterns.add(SeasonalPattern(
          period: 'Jour ${entry.key}',
          avgSpo2: avgSpo2,
          avgBreathingRate: avgBreathing,
          occurrences: dayData.length,
          significance: _calculateSignificance(dayData),
        ));
      }
    }

    return patterns;
  }

  /// NOUVEAU: Calcule tendances long-terme
  LongTermTrendData _calculateLongTermTrends(List<HealthData> history) {
    // Diviser l'historique en segments temporels
    final recentData = history.length > 7 ? history.sublist(history.length - 7) : history;
    final olderData = history.length > 14 ? history.sublist(0, history.length - 7) : <HealthData>[];

    if (olderData.isEmpty) {
      return LongTermTrendData.insufficient();
    }

    // Calculer moyennes des segments
    final recentAvg = _calculateAverages(recentData);
    final olderAvg = _calculateAverages(olderData);

    // Calculer évolution
    final spo2Evolution = recentAvg.spo2 - olderAvg.spo2;
    final breathingEvolution = recentAvg.breathingRate - olderAvg.breathingRate;
    final pefEvolution = recentAvg.pef - olderAvg.pef;

    return LongTermTrendData(
      spo2Trend: spo2Evolution,
      breathingTrend: breathingEvolution, 
      pefTrend: pefEvolution,
      trendStrength: _calculateTrendStrength(history),
      dataPoints: history.length,
    );
  }

  /// NOUVEAU: Identifie cycles récurrents
  List<RecurringCycle> _identifyRecurringCycles(List<HealthData> history) {
    final cycles = <RecurringCycle>[];
    
    // Analyser cycles de 3, 7, 14 jours
    for (var cycleLength in [3, 7, 14]) {
      if (history.length >= cycleLength * 2) {
        final cycle = _detectCycle(history, cycleLength);
        if (cycle != null) cycles.add(cycle);
      }
    }

    return cycles;
  }

  /// NOUVEAU: Analyse patterns hebdomadaires  
  WeeklyPattern _analyzeWeeklyPatterns(List<HealthData> history) {
    final weekdayData = <int, List<double>>{};
    final weekdayBreathing = <int, List<int>>{};

    // Grouper par jour de semaine
    for (var data in history) {
      final weekday = data.date.weekday;
      weekdayData.putIfAbsent(weekday, () => []).add(data.spo2.toDouble());
      weekdayBreathing.putIfAbsent(weekday, () => []).add(data.breathingRate);
    }

    // Calculer moyennes par jour
    final dailyAverages = <int, double>{};
    final dailyBreathingAvg = <int, double>{};
    
    for (var day = 1; day <= 7; day++) {
      if (weekdayData.containsKey(day) && weekdayData[day]!.isNotEmpty) {
        dailyAverages[day] = weekdayData[day]!.reduce((a, b) => a + b) / weekdayData[day]!.length;
        dailyBreathingAvg[day] = weekdayBreathing[day]!.reduce((a, b) => a + b) / weekdayBreathing[day]!.length;
      }
    }

    return WeeklyPattern(
      spo2ByDay: dailyAverages,
      breathingByDay: dailyBreathingAvg,
      bestDay: _findBestDay(dailyAverages),
      worstDay: _findWorstDay(dailyAverages),
    );
  }

  /// NOUVEAU: Corrélations étendues
  ExtendedCorrelations _calculateExtendedCorrelations(List<HealthData> history) {
    // Corrélation SpO2 vs Fréquence respiratoire
    final spo2Breathing = _calculateCorrelation(
      history.map((d) => d.spo2.toDouble()).toList(),
      history.map((d) => d.breathingRate.toDouble()).toList(),
    );

    // Corrélation SpO2 vs PEF
    final spo2Pef = _calculateCorrelation(
      history.map((d) => d.spo2.toDouble()).toList(),
      history.map((d) => d.pef).toList(),
    );

    // Corrélation temporelle (heure vs paramètres)
    final hourlyCorrelation = _calculateHourlyCorrelation(history);

    return ExtendedCorrelations(
      spo2BreathingCorr: spo2Breathing,
      spo2PefCorr: spo2Pef,
      hourlyTrendCorr: hourlyCorrelation,
      significantCorrelations: _identifySignificantCorrelations(history),
    );
  }

  /// NOUVEAU: Génère prédictions de risque basées sur l'historique complet
  RiskPredictions _generateRiskPredictions(List<HealthData> history) {
    final recent = history.length > 7 ? history.sublist(history.length - 7) : history;
    
    // Prédiction 6h basée sur tendance récente
    final next6h = _predictNext6Hours(recent);
    
    // Prédiction 24h basée sur patterns quotidiens
    final next24h = _predictNext24Hours(history);
    
    // Prédiction 7j basée sur cycles hebdomadaires
    final next7d = _predictNext7Days(history);

    return RiskPredictions(
      next6Hours: next6h,
      next24Hours: next24h,  
      next7Days: next7d,
      confidence: _calculatePredictionConfidence(history),
    );
  }

  /// Analyse la tendance SpO₂
  List<TrendAlert> _analyzeSpo2Trend(List<HealthData> history) {
    final alerts = <TrendAlert>[];
    final spo2Values = history.map((d) => d.spo2).toList();

    if (spo2Values.length < 3) return alerts;

    if (_isDecreasingTrend(spo2Values)) {
      final dailyDecline = _calculateDailyDecline(spo2Values);
      final daysUntilCritical = _predictCriticalDay(spo2Values, threshold: 90);
      final currentSpo2 = spo2Values.last;

      String severity;
      if (daysUntilCritical <= 1) {
        severity = 'high';
      } else if (daysUntilCritical <= 3) {
        severity = 'medium';
      } else {
        severity = 'low';
      }

      alerts.add(TrendAlert(
        type: 'spo2_decline',
        severity: severity,
        title: '⚠️ SpO₂ en baisse progressive',
        message:
            'Votre SpO₂ baisse de ${dailyDecline.toStringAsFixed(1)}% par jour. '
            'Valeur actuelle: $currentSpo2%. '
            'Au rythme actuel, vous atteindrez le seuil critique (90%) dans $daysUntilCritical jour${daysUntilCritical > 1 ? 's' : ''}.',
        actions: [
          'Augmentez vos exercices respiratoires dès aujourd\'hui (10 min matin + soir)',
          'Consultez votre médecin cette semaine (pas d\'urgence immédiate)',
          'Surveillez 2x par jour au lieu d\'1x',
          'Évitez les activités physiques intenses',
        ],
        preventionWindow: Duration(days: daysUntilCritical),
        metadata: {
          'daily_decline': dailyDecline,
          'current_value': currentSpo2,
          'critical_threshold': 90,
          'days_until_critical': daysUntilCritical,
        },
      ));
    }

    return alerts;
  }

  // NOUVELLES MÉTHODES UTILITAIRES POUR ANALYSE LONG-TERME

  HealthAverages _calculateAverages(List<HealthData> data) {
    if (data.isEmpty) return HealthAverages.zero();
    
    final spo2Sum = data.map((d) => d.spo2).reduce((a, b) => a + b);
    final breathingSum = data.map((d) => d.breathingRate).reduce((a, b) => a + b);  
    final pefSum = data.map((d) => d.pef).reduce((a, b) => a + b);
    
    return HealthAverages(
      spo2: spo2Sum / data.length,
      breathingRate: breathingSum / data.length,
      pef: pefSum / data.length,
    );
  }

  double _calculateTrendStrength(List<HealthData> history) {
    if (history.length < 3) return 0.0;
    
    final spo2Values = history.map((d) => d.spo2.toDouble()).toList();
    final trend = _calculateLinearTrend(spo2Values);
    return trend.abs();
  }

  double _calculateSignificance(List<HealthData> data) {
    if (data.length < 2) return 0.0;
    
    final spo2Values = data.map((d) => d.spo2.toDouble()).toList();
    final variance = _calculateVariance(spo2Values);
    return 1.0 / (1.0 + variance); // Plus la variance est faible, plus c'est significatif
  }

  RecurringCycle? _detectCycle(List<HealthData> history, int cycleLength) {
    if (history.length < cycleLength * 2) return null;
    
    final cycles = <List<HealthData>>[];
    
    // Diviser en cycles
    for (var i = 0; i <= history.length - cycleLength; i += cycleLength) {
      final cycle = history.sublist(i, math.min(i + cycleLength, history.length));
      if (cycle.length == cycleLength) cycles.add(cycle);
    }
    
    if (cycles.length < 2) return null;
    
    // Calculer similarité entre cycles
    double similarity = 0.0;
    for (var i = 0; i < cycles.length - 1; i++) {
      similarity += _calculateCycleSimilarity(cycles[i], cycles[i + 1]);
    }
    similarity /= (cycles.length - 1);
    
    if (similarity > 0.7) { // 70% de similarité minimum
      return RecurringCycle(
        lengthDays: cycleLength,
        similarity: similarity,
        occurrences: cycles.length,
        pattern: _describeCyclePattern(cycles.first),
      );
    }
    
    return null;
  }

  int _findBestDay(Map<int, double> dailyAverages) {
    if (dailyAverages.isEmpty) return 1;
    return dailyAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _findWorstDay(Map<int, double> dailyAverages) {
    if (dailyAverages.isEmpty) return 1;
    return dailyAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;
    
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    
    double numerator = 0.0;
    double denomX = 0.0;
    double denomY = 0.0;
    
    for (var i = 0; i < x.length; i++) {
      final deltaX = x[i] - meanX;
      final deltaY = y[i] - meanY;
      
      numerator += deltaX * deltaY;
      denomX += deltaX * deltaX;
      denomY += deltaY * deltaY;
    }
    
    if (denomX == 0 || denomY == 0) return 0.0;
    return numerator / (math.sqrt(denomX) * math.sqrt(denomY));
  }

  double _calculateHourlyCorrelation(List<HealthData> history) {
    final hours = history.map((d) => d.date.hour.toDouble()).toList();
    final spo2Values = history.map((d) => d.spo2.toDouble()).toList();
    return _calculateCorrelation(hours, spo2Values);
  }

  List<String> _identifySignificantCorrelations(List<HealthData> history) {
    final correlations = <String>[];
    
    // Test différentes corrélations
    final spo2Breathing = _calculateCorrelation(
      history.map((d) => d.spo2.toDouble()).toList(),
      history.map((d) => d.breathingRate.toDouble()).toList(),
    );
    
    if (spo2Breathing.abs() > 0.5) {
      correlations.add('SpO₂ et respiration ${spo2Breathing > 0 ? "positivement" : "négativement"} corrélées');
    }
    
    return correlations;
  }

  RiskLevel _predictNext6Hours(List<HealthData> recent) {
    if (recent.isEmpty) return RiskLevel.low;
    
    final trend = _calculateLinearTrend(recent.map((d) => d.spo2.toDouble()).toList());
    final currentSpo2 = recent.last.spo2;
    
    // Prédiction simple basée sur la tendance
    final predicted6h = currentSpo2 + (trend * 0.25); // 6h = 1/4 de jour
    
    if (predicted6h < 92) return RiskLevel.high;
    if (predicted6h < 95) return RiskLevel.medium;
    return RiskLevel.low;
  }

  RiskLevel _predictNext24Hours(List<HealthData> history) {
    if (history.isEmpty) return RiskLevel.low;
    
    final recent7days = history.length > 7 ? history.sublist(history.length - 7) : history;
    final avgRisk = _calculateAverageRisk(recent7days);
    
    // Logique de prédiction 24h basée sur pattern récent
    final criticalCount = recent7days.where((d) => d.riskLevel == RiskLevel.high).length;
    final moderateCount = recent7days.where((d) => d.riskLevel == RiskLevel.medium).length;
    
    if (criticalCount >= 2 || (criticalCount >= 1 && moderateCount >= 3)) {
      return RiskLevel.high;
    }
    if (moderateCount >= 3) {
      return RiskLevel.medium;  
    }
    
    return RiskLevel.low;
  }

  RiskLevel _predictNext7Days(List<HealthData> history) {
    if (history.length < 7) return RiskLevel.low;
    
    // Analyse des 2-3 dernières semaines si disponible
    final recentWeeks = history.length > 21 ? history.sublist(history.length - 21) : history;
    final weeklyTrend = _calculateWeeklyTrend(recentWeeks);
    
    if (weeklyTrend < -2.0) return RiskLevel.high;  // Forte dégradation
    if (weeklyTrend < -1.0) return RiskLevel.medium; // Dégradation modérée  
    return RiskLevel.low;
  }

  double _calculatePredictionConfidence(List<HealthData> history) {
    // Plus on a de données, plus on est confiant
    final dataFactor = math.min(history.length / 30.0, 1.0); // Max à 30 jours
    
    // Stabilité des données (moins de variabilité = plus de confiance)
    final spo2Values = history.map((d) => d.spo2.toDouble()).toList();
    final variance = _calculateVariance(spo2Values);
    final stabilityFactor = math.max(0.0, 1.0 - (variance / 100.0));
    
    return (dataFactor + stabilityFactor) / 2.0;
  }

  // MÉTHODES UTILITAIRES ADDITIONNELLES

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

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquaredDiffs = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return sumSquaredDiffs / (values.length - 1);
  }

  double _calculateTrendConfidence(List<double> values) {
    if (values.length < 3) return 0.0;
    
    final variance = _calculateVariance(values);
    final range = values.reduce(math.max) - values.reduce(math.min);
    
    // Confiance basée sur la consistance de la tendance
    return math.max(0.0, 1.0 - (variance / (range * range)));
  }

  double _calculateCycleSimilarity(List<HealthData> cycle1, List<HealthData> cycle2) {
    if (cycle1.length != cycle2.length) return 0.0;

    double totalDiff = 0.0;
    for (var i = 0; i < cycle1.length; i++) {
      final spo2Diff = (cycle1[i].spo2 - cycle2[i].spo2).abs();
      final breathingDiff = (cycle1[i].breathingRate - cycle2[i].breathingRate).abs();
      totalDiff += spo2Diff + (breathingDiff * 0.5); // SpO2 a plus de poids
    }

    final avgDiff = totalDiff / cycle1.length;
    return math.max(0.0, 1.0 - (avgDiff / 20.0)); // Normalisation
  }

  String _describeCyclePattern(List<HealthData> cycle) {
    if (cycle.isEmpty) return 'Pattern indéterminé';

    final avgSpo2 = cycle.map((d) => d.spo2).reduce((a, b) => a + b) / cycle.length;
    final avgBreathing = cycle.map((d) => d.breathingRate).reduce((a, b) => a + b) / cycle.length;

    final spo2Trend = _calculateLinearTrend(cycle.map((d) => d.spo2.toDouble()).toList());
    
    String description = 'SpO₂ moyen: ${avgSpo2.toStringAsFixed(1)}%, ';
    description += 'Respiration: ${avgBreathing.toStringAsFixed(1)} bpm';
    
    if (spo2Trend > 0.5) {
      description += ' (tendance amélioration)';
    } else if (spo2Trend < -0.5) {
      description += ' (tendance dégradation)';
    } else {
      description += ' (stable)';
    }

    return description;
  }

  RiskLevel _calculateAverageRisk(List<HealthData> data) {
    if (data.isEmpty) return RiskLevel.low;

    final riskScores = data.map((d) {
      switch (d.riskLevel) {
        case RiskLevel.low: return 1;
        case RiskLevel.medium: return 2;
        case RiskLevel.high: return 3;
      }
    }).toList();

    final avgScore = riskScores.reduce((a, b) => a + b) / riskScores.length;

    if (avgScore >= 2.5) return RiskLevel.high;
    if (avgScore >= 1.5) return RiskLevel.medium;
    return RiskLevel.low;
  }

  double _calculateWeeklyTrend(List<HealthData> recentWeeks) {
    if (recentWeeks.length < 7) return 0.0;

    final spo2Values = recentWeeks.map((d) => d.spo2.toDouble()).toList();
    return _calculateLinearTrend(spo2Values) * 7; // Tendance par semaine
  }
  

  /// Analyse la tendance de fréquence respiratoire
  List<TrendAlert> _analyzeBreathingRateTrend(List<HealthData> history) {
    final alerts = <TrendAlert>[];
    final breathingValues = history.map((d) => d.breathingRate).toList();

    if (_isIncreasingTrend(breathingValues)) {
      final dailyIncrease = _calculateDailyDecline(breathingValues).abs();
      final currentRate = breathingValues.last;

      alerts.add(TrendAlert(
        type: 'breathing_rate_increase',
        severity: currentRate > 22 ? 'high' : 'medium',
        title: '📈 Fréquence respiratoire en hausse',
        message:
            'Votre fréquence respiratoire augmente progressivement (+${dailyIncrease.toStringAsFixed(1)} bpm/jour). '
            'Valeur actuelle: $currentRate bpm (normal: 12-20).',
        actions: [
          'Pratiquez la respiration lèvres pincées (3x par jour)',
          'Vérifiez que votre traitement est bien pris',
          'Reposez-vous davantage',
          'Consultez si > 25 bpm de façon persistante',
        ],
        preventionWindow: Duration(days: 2),
        metadata: {
          'daily_increase': dailyIncrease,
          'current_value': currentRate,
          'normal_range': '12-20 bpm',
        },
      ));
    }

    return alerts;
  }

  /// Analyse la tendance PEF
  List<TrendAlert> _analyzePefTrend(List<HealthData> history) {
    final alerts = <TrendAlert>[];
    final pefValues = history.map((d) => d.pef).toList();

    if (_isDecreasingTrend(pefValues.map((p) => p.toInt()).toList())) {
      final dailyDecline = _calculateDailyDecline(
        pefValues.map((p) => p.toInt()).toList(),
      );
      final currentPef = pefValues.last;
      final percentageDecline = (dailyDecline / currentPef * 100).abs();

      alerts.add(TrendAlert(
        type: 'pef_decline',
        severity: percentageDecline > 5 ? 'high' : 'medium',
        title: '📉 Débit de pointe en baisse',
        message:
            'Votre PEF diminue de ${dailyDecline.toStringAsFixed(0)} L/min par jour '
            '(${percentageDecline.toStringAsFixed(1)}%). '
            'Valeur actuelle: ${currentPef.toStringAsFixed(0)} L/min.',
        actions: [
          'Utilisez votre débitmètre 2x par jour',
          'Revoyez votre technique d\'inhalation',
          'Évitez les allergènes connus',
          'Consultez si PEF < 250 L/min',
        ],
        preventionWindow: Duration(days: 3),
        metadata: {
          'daily_decline': dailyDecline,
          'current_value': currentPef,
          'percentage_decline': percentageDecline,
        },
      ));
    }

    return alerts;
  }

  /// Détecte les patterns horaires
  List<TrendAlert> _detectTimePatterns(List<HealthData> history) {
    final alerts = <TrendAlert>[];

    // Grouper par heure de la journée
    final morningData = <HealthData>[];
    final eveningData = <HealthData>[];

    for (var data in history) {
      final hour = data.date.hour;
      if (hour >= 5 && hour < 12) {
        morningData.add(data);
      } else if (hour >= 17 && hour < 23) {
        eveningData.add(data);
      }
    }

    // Comparer matin vs soir
    if (morningData.length >= 2 && eveningData.length >= 2) {
      final morningAvgSpo2 =
          morningData.map((d) => d.spo2).reduce((a, b) => a + b) /
              morningData.length;
      final eveningAvgSpo2 =
          eveningData.map((d) => d.spo2).reduce((a, b) => a + b) /
              eveningData.length;

      if (eveningAvgSpo2 < morningAvgSpo2 - 2) {
        alerts.add(TrendAlert(
          type: 'evening_deterioration',
          severity: 'medium',
          title: '🌙 Pattern nocturne détecté',
          message:
              'Vos paramètres se dégradent systématiquement en soirée. '
              'SpO₂ moyen: ${morningAvgSpo2.toStringAsFixed(1)}% (matin) vs ${eveningAvgSpo2.toStringAsFixed(1)}% (soir).',
          actions: [
            'Prenez votre traitement à 17h au lieu de 20h',
            'Évitez l\'effort physique après le dîner',
            'Aérez votre chambre 30min avant le coucher',
            'Surveillez votre position de sommeil (tête surélevée)',
          ],
          preventionWindow: Duration(hours: 24),
          metadata: {
            'morning_avg_spo2': morningAvgSpo2,
            'evening_avg_spo2': eveningAvgSpo2,
            'difference': morningAvgSpo2 - eveningAvgSpo2,
          },
        ));
      }
    }

    return alerts;
  }

  /// Détecte les corrélations dangereuses multi-paramètres
  List<TrendAlert> _detectCorrelatedDecline(List<HealthData> history) {
    final alerts = <TrendAlert>[];

    if (history.length < 3) return alerts;

    final spo2Values = history.map((d) => d.spo2).toList();
    final breathingValues = history.map((d) => d.breathingRate).toList();
    final pefValues = history.map((d) => d.pef).toList();

    final spo2Declining = _isDecreasingTrend(spo2Values);
    final breathingIncreasing = _isIncreasingTrend(breathingValues);
    final pefDeclining =
        _isDecreasingTrend(pefValues.map((p) => p.toInt()).toList());

    // Détérioration combinée = DANGER
    if ((spo2Declining && breathingIncreasing) ||
        (spo2Declining && pefDeclining) ||
        (breathingIncreasing && pefDeclining)) {
      alerts.add(TrendAlert(
        type: 'multi_param_deterioration',
        severity: 'high',
        title: '🚨 Détérioration combinée détectée',
        message: 'Plusieurs paramètres se dégradent simultanément:\n'
            '${spo2Declining ? '• SpO₂ en baisse\n' : ''}'
            '${breathingIncreasing ? '• Fréquence respiratoire en hausse\n' : ''}'
            '${pefDeclining ? '• PEF en baisse\n' : ''}'
            'Risque de crise dans les 24-48h.',
        actions: [
          '🚨 URGENT : Préparez votre traitement de secours',
          'Annulez vos activités physiques prévues',
          'Contactez votre médecin AUJOURD\'HUI pour ajustement traitement',
          'Surveillez TOUTES les 4 heures',
          'Ayez le 185 en accès rapide',
        ],
        preventionWindow: Duration(hours: 36),
        metadata: {
          'spo2_declining': spo2Declining,
          'breathing_increasing': breathingIncreasing,
          'pef_declining': pefDeclining,
        },
      ));
    }

    return alerts;
  }

  /// Détecte une variabilité excessive (instabilité)
  List<TrendAlert> _detectExcessiveVariability(List<HealthData> history) {
    final alerts = <TrendAlert>[];

    final spo2Values = history.map((d) => d.spo2.toDouble()).toList();
    final spo2Variability = _calculateVariability(spo2Values);

    if (spo2Variability > 3.0) {
      alerts.add(TrendAlert(
        type: 'spo2_instability',
        severity: spo2Variability > 5 ? 'high' : 'medium',
        title: '⚡ Instabilité SpO₂ détectée',
        message:
            'Vos valeurs de SpO₂ fluctuent beaucoup (écart-type: ${spo2Variability.toStringAsFixed(1)}%). '
            'Cette instabilité est un facteur de risque.',
        actions: [
          'Identifiez les facteurs déclencheurs (activité, heure, environnement)',
          'Maintenez un rythme régulier (sommeil, repas, activité)',
          'Évitez les variations brutales de température',
          'Consultez pour stabiliser votre traitement',
        ],
        preventionWindow: Duration(days: 2),
        metadata: {
          'variability': spo2Variability,
          'values': spo2Values,
        },
      ));
    }

    return alerts;
  }

  /// Détecte si une série de valeurs est en tendance décroissante
  bool _isDecreasingTrend(List<int> values) {
    if (values.length < 3) return false;

    final slope = _calculateSlope(values.map((v) => v.toDouble()).toList());
    return slope < -0.3; // Déclin significatif > 0.3 par jour
  }

  /// Détecte si une série de valeurs est en tendance croissante
  bool _isIncreasingTrend(List<int> values) {
    if (values.length < 3) return false;

    final slope = _calculateSlope(values.map((v) => v.toDouble()).toList());
    return slope > 0.3; // Augmentation significative > 0.3 par jour
  }

  /// Calcule le déclin quotidien moyen
  double _calculateDailyDecline(List<int> values) {
    return _calculateSlope(values.map((v) => v.toDouble()).toList()).abs();
  }

  /// Calcule la pente de régression linéaire
  double _calculateSlope(List<double> values) {
    final n = values.length;
    if (n < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Prédit le jour où le seuil critique sera atteint
  int _predictCriticalDay(List<int> values, {required int threshold}) {
    final currentValue = values.last;
    final decline = _calculateDailyDecline(values);

    if (decline == 0 || currentValue >= threshold) {
      return 999; // Pas de tendance ou déjà au-dessus
    }

    final daysUntilCritical = ((currentValue - threshold) / decline).ceil();
    return daysUntilCritical.clamp(1, 30);
  }

  /// Calcule la variabilité (écart-type)
  double _calculateVariability(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((v) => math.pow(v - mean, 2))
            .reduce((a, b) => a + b) /
        values.length;

    return math.sqrt(variance);
  }

  /// Détecte les patterns récurrents (ex: baisse tous les lundis)
  Future<List<RecurringPattern>> detectRecurringPatterns(
    List<HealthData> history30days,
  ) async {
    final patterns = <RecurringPattern>[];

    if (history30days.length < 14) return patterns;

    // Pattern hebdomadaire
    final weekdayAverages = <int, List<int>>{};
    for (var data in history30days) {
      final weekday = data.date.weekday;
      weekdayAverages.putIfAbsent(weekday, () => []);
      weekdayAverages[weekday]!.add(data.spo2);
    }

    // Trouver le jour de la semaine avec les valeurs les plus basses
    int? worstDay;
    double worstAvg = 100;
    weekdayAverages.forEach((day, values) {
      if (values.length >= 2) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        if (avg < worstAvg) {
          worstAvg = avg;
          worstDay = day;
        }
      }
    });

    if (worstDay != null && worstAvg < 95) {
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
      patterns.add(RecurringPattern(
        type: 'weekly_decline',
        description: 'Baisse récurrente le ${dayNames[worstDay!]}',
        occurrences: weekdayAverages[worstDay]!.length,
        confidence: 0.8,
        parameters: {
          'day_of_week': worstDay,
          'average_spo2': worstAvg,
        },
      ));
    }

    return patterns;
  }
}
