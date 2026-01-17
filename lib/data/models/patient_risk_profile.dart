import 'trend_models.dart';

/// Profil de risque personnalisé pour un patient
class PatientRiskProfile {
  final int userId;

  // Baseline personnel (valeurs "normales" POUR CE PATIENT)
  final double baselineSpo2;
  final int baselineBreathingRate;
  final double baselinePef;

  // Patterns identifiés
  final List<RecurringPattern> patterns;

  // Triggers personnels
  final List<PersonalTrigger> triggers;

  // Fenêtres de risque temporelles
  final TimeOfDayRisk morningRisk;
  final TimeOfDayRisk afternoonRisk;
  final TimeOfDayRisk eveningRisk;
  final TimeOfDayRisk nightRisk;

  // Métadonnées
  final DateTime lastUpdated;
  final int daysAnalyzed;

  PatientRiskProfile({
    required this.userId,
    required this.baselineSpo2,
    required this.baselineBreathingRate,
    required this.baselinePef,
    required this.patterns,
    required this.triggers,
    required this.morningRisk,
    required this.afternoonRisk,
    required this.eveningRisk,
    required this.nightRisk,
    required this.lastUpdated,
    required this.daysAnalyzed,
  });

  /// Détecte une anomalie par rapport au profil personnel
  bool isAnomalousForThisPatient(
    int spo2,
    int breathingRate,
    double pef,
  ) {
    final spo2Drop = baselineSpo2 - spo2;
    final breathingRateIncrease = breathingRate - baselineBreathingRate;
    final pefDrop = baselinePef - pef;

    // Anomalie si:
    // - SpO₂ baisse de plus de 2% vs baseline
    // - Fréquence resp. augmente de plus de 4 bpm
    // - PEF baisse de plus de 15%
    return spo2Drop > 2 ||
        breathingRateIncrease > 4 ||
        (pefDrop / baselinePef) > 0.15;
  }

  /// Retourne le risque pour la période actuelle
  TimeOfDayRisk getCurrentTimeRisk() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return morningRisk;
    if (hour >= 12 && hour < 17) return afternoonRisk;
    if (hour >= 17 && hour < 22) return eveningRisk;
    return nightRisk;
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'baseline_spo2': baselineSpo2,
        'baseline_breathing_rate': baselineBreathingRate,
        'baseline_pef': baselinePef,
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'triggers': triggers.map((t) => t.toJson()).toList(),
        'morning_risk': morningRisk.toJson(),
        'afternoon_risk': afternoonRisk.toJson(),
        'evening_risk': eveningRisk.toJson(),
        'night_risk': nightRisk.toJson(),
        'last_updated': lastUpdated.toIso8601String(),
        'days_analyzed': daysAnalyzed,
      };

  factory PatientRiskProfile.fromJson(Map<String, dynamic> json) =>
      PatientRiskProfile(
        userId: json['user_id'],
        baselineSpo2: json['baseline_spo2'],
        baselineBreathingRate: json['baseline_breathing_rate'],
        baselinePef: json['baseline_pef'],
        patterns: (json['patterns'] as List)
            .map((p) => RecurringPattern.fromJson(p))
            .toList(),
        triggers: (json['triggers'] as List)
            .map((t) => PersonalTrigger.fromJson(t))
            .toList(),
        morningRisk: TimeOfDayRisk.fromJson(json['morning_risk']),
        afternoonRisk: TimeOfDayRisk.fromJson(json['afternoon_risk']),
        eveningRisk: TimeOfDayRisk.fromJson(json['evening_risk']),
        nightRisk: TimeOfDayRisk.fromJson(json['night_risk']),
        lastUpdated: DateTime.parse(json['last_updated']),
        daysAnalyzed: json['days_analyzed'],
      );

  /// Crée un profil par défaut pour un nouveau patient
  factory PatientRiskProfile.createDefault(int userId) {
    return PatientRiskProfile(
      userId: userId,
      baselineSpo2: 97.0,
      baselineBreathingRate: 16,
      baselinePef: 400.0,
      patterns: [],
      triggers: [],
      morningRisk: TimeOfDayRisk(
        period: 'morning',
        riskScore: 25,
        description: 'Risque normal',
      ),
      afternoonRisk: TimeOfDayRisk(
        period: 'afternoon',
        riskScore: 20,
        description: 'Risque faible',
      ),
      eveningRisk: TimeOfDayRisk(
        period: 'evening',
        riskScore: 30,
        description: 'Risque légèrement élevé',
      ),
      nightRisk: TimeOfDayRisk(
        period: 'night',
        riskScore: 35,
        description: 'Risque modéré',
      ),
      lastUpdated: DateTime.now(),
      daysAnalyzed: 0,
    );
  }
}
