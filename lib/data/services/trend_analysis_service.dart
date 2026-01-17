import 'dart:math';
import '../models/health_data.dart';
import '../models/trend_models.dart';

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

  /// Analyse la tendance SpO₂
  List<TrendAlert> _analyzeSpo2Trend(List<HealthData> history) {
    final alerts = <TrendAlert>[];
    final spo2Values = history.map((d) => d.spo2).toList();

    if (_isDecreasingTrend(spo2Values)) {
      final dailyDecline = _calculateDailyDecline(spo2Values);
      final daysUntilCritical =
          _predictCriticalDay(spo2Values, threshold: 90);
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
            .map((v) => pow(v - mean, 2))
            .reduce((a, b) => a + b) /
        values.length;

    return sqrt(variance);
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
