import '../../core/enums/app_enums.dart';

/// Modèle pour l'analyse de tendances long-terme
class LongTermTrendAnalysis {
  final List<SeasonalPattern> seasonalPatterns;
  final LongTermTrendData longTermTrends;
  final List<RecurringCycle> recurringCycles;
  final WeeklyPattern weeklyPatterns;
  final ExtendedCorrelations extendedCorrelations;
  final RiskPredictions riskPredictions;
  final bool hasInsufficientData;

  LongTermTrendAnalysis({
    this.seasonalPatterns = const [],
    required this.longTermTrends,
    this.recurringCycles = const [],
    required this.weeklyPatterns,
    required this.extendedCorrelations,
    required this.riskPredictions,
    this.hasInsufficientData = false,
  });

  factory LongTermTrendAnalysis.insufficient() {
    return LongTermTrendAnalysis(
      longTermTrends: LongTermTrendData.insufficient(),
      weeklyPatterns: WeeklyPattern.empty(),
      extendedCorrelations: ExtendedCorrelations.empty(),
      riskPredictions: RiskPredictions.empty(),
      hasInsufficientData: true,
    );
  }
}

/// Pattern saisonnier détecté
class SeasonalPattern {
  final String period;
  final double avgSpo2;
  final double avgBreathingRate;
  final int occurrences;
  final double significance;

  SeasonalPattern({
    required this.period,
    required this.avgSpo2,
    required this.avgBreathingRate,
    required this.occurrences,
    required this.significance,
  });
}

/// Données de tendance long-terme
class LongTermTrendData {
  final double spo2Trend;
  final double breathingTrend;
  final double pefTrend;
  final double trendStrength;
  final int dataPoints;
  final bool isInsufficient;

  LongTermTrendData({
    required this.spo2Trend,
    required this.breathingTrend,
    required this.pefTrend,
    required this.trendStrength,
    required this.dataPoints,
    this.isInsufficient = false,
  });

  factory LongTermTrendData.insufficient() {
    return LongTermTrendData(
      spo2Trend: 0.0,
      breathingTrend: 0.0,
      pefTrend: 0.0,
      trendStrength: 0.0,
      dataPoints: 0,
      isInsufficient: true,
    );
  }

  String get spo2TrendDescription {
    if (isInsufficient) return 'Données insuffisantes';
    if (spo2Trend > 0.5) return 'Amélioration significative';
    if (spo2Trend > 0.1) return 'Légère amélioration';
    if (spo2Trend > -0.1) return 'Stable';
    if (spo2Trend > -0.5) return 'Légère dégradation';
    return 'Dégradation significative';
  }
}

/// Cycle récurrent détecté
class RecurringCycle {
  final int lengthDays;
  final double similarity;
  final int occurrences;
  final String pattern;

  RecurringCycle({
    required this.lengthDays,
    required this.similarity,
    required this.occurrences,
    required this.pattern,
  });
}

/// Pattern hebdomadaire
class WeeklyPattern {
  final Map<int, double> spo2ByDay;
  final Map<int, double> breathingByDay;
  final int bestDay;
  final int worstDay;

  WeeklyPattern({
    required this.spo2ByDay,
    required this.breathingByDay,
    required this.bestDay,
    required this.worstDay,
  });

  factory WeeklyPattern.empty() {
    return WeeklyPattern(
      spo2ByDay: {},
      breathingByDay: {},
      bestDay: 1,
      worstDay: 1,
    );
  }

  String get bestDayName => _getDayName(bestDay);
  String get worstDayName => _getDayName(worstDay);

  String _getDayName(int weekday) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return weekday >= 1 && weekday <= 7 ? days[weekday] : 'Inconnu';
  }
}

/// Corrélations étendues
class ExtendedCorrelations {
  final double spo2BreathingCorr;
  final double spo2PefCorr;
  final double hourlyTrendCorr;
  final List<String> significantCorrelations;

  ExtendedCorrelations({
    required this.spo2BreathingCorr,
    required this.spo2PefCorr,
    required this.hourlyTrendCorr,
    required this.significantCorrelations,
  });

  factory ExtendedCorrelations.empty() {
    return ExtendedCorrelations(
      spo2BreathingCorr: 0.0,
      spo2PefCorr: 0.0,
      hourlyTrendCorr: 0.0,
      significantCorrelations: [],
    );
  }
}

/// Prédictions de risque multi-horizon
class RiskPredictions {
  final RiskLevel next6Hours;
  final RiskLevel next24Hours;
  final RiskLevel next7Days;
  final double confidence;

  RiskPredictions({
    required this.next6Hours,
    required this.next24Hours,
    required this.next7Days,
    required this.confidence,
  });

  factory RiskPredictions.empty() {
    return RiskPredictions(
      next6Hours: RiskLevel.low,
      next24Hours: RiskLevel.low,
      next7Days: RiskLevel.low,
      confidence: 0.0,
    );
  }

  String get confidenceDescription {
    if (confidence > 0.8) return 'Très élevée';
    if (confidence > 0.6) return 'Élevée';
    if (confidence > 0.4) return 'Modérée';
    if (confidence > 0.2) return 'Faible';
    return 'Très faible';
  }
}

/// Moyennes de santé
class HealthAverages {
  final double spo2;
  final double breathingRate;
  final double pef;

  HealthAverages({
    required this.spo2,
    required this.breathingRate,
    required this.pef,
  });

  factory HealthAverages.zero() {
    return HealthAverages(spo2: 0.0, breathingRate: 0.0, pef: 0.0);
  }
}