import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/trend_models.dart';
import '../models/fragility_models.dart';
import '../models/fragility_forecast_models.dart';
import '../models/long_term_analysis_models.dart';
import '../models/multi_horizon_alerts_models.dart';
import '../models/actionable_recommendation.dart';
import '../models/modele_alerte.dart';
import 'trend_analysis_service.dart';
import 'fragility_score_service.dart';
import 'personalized_prevention_service.dart';

/// Moteur d'alertes prédictives intégrant tous les services
class PredictiveAlertEngine {
  static final PredictiveAlertEngine _instance =
      PredictiveAlertEngine._internal();
  factory PredictiveAlertEngine() => _instance;
  PredictiveAlertEngine._internal();

  final TrendAnalysisService _trendService = TrendAnalysisService();
  final FragilityScoreService _fragilityService = FragilityScoreService();
  final PersonalizedPreventionService _preventionService =
      PersonalizedPreventionService();

  /// Génère des alertes prédictives 24-72h à l'avance
  Future<PredictiveAnalysisResult> generatePredictiveAlerts(
    PatientRiskProfile profile,
    List<HealthData> history,
  ) async {
    if (history.isEmpty) {
      return PredictiveAnalysisResult.empty();
    }

    final currentData = history.last;
    final last7days =
        history.length > 7 ? history.sublist(history.length - 7) : history;
    final last14days =
        history.length > 14 ? history.sublist(history.length - 14) : history;

    // 1️⃣ Analyse de tendances (prédiction 2-3 jours)
    final trendAlerts = await _trendService.detectDangerousTrends(last7days);

    // 2️⃣ Score de fragilité
    final fragilityScore =
        await _fragilityService.calculateCurrentFragility(last14days, profile);

    // 3️⃣ Conseils personnalisés
    final preventionAdvice = await _preventionService.getPersonalizedAdvice(
      profile,
      currentData,
      last7days,
    );

    // 4️⃣ Recommandations actionnables
    final actionableRecommendations =
        await _preventionService.getActionableRecommendations(
      profile,
      currentData,
      last7days,
    );

    // 5️⃣ Convertir trend alerts en ModeleAlerte
    final modeleAlertes = _convertTrendAlertsToModeleAlerte(trendAlerts);

    // 6️⃣ Générer alerte de fragilité si score élevé
    if (fragilityScore.level == FragilityLevel.critical ||
        fragilityScore.level == FragilityLevel.elevated) {
      modeleAlertes.add(_createFragilityAlert(fragilityScore));
    }

    return PredictiveAnalysisResult(
      trendAlerts: trendAlerts,
      fragilityScore: fragilityScore,
      preventionAdvice: preventionAdvice,
      actionableRecommendations: actionableRecommendations,
      modeleAlertes: modeleAlertes,
      analysisTimestamp: DateTime.now(),
    );
  }

  /// NOUVEAU: Génère des alertes multi-temporelles (6h/24h/7j)
  Future<MultiHorizonAlerts> generateMultiHorizonAlerts(
    PatientRiskProfile profile,
    List<HealthData> fullHistory,
  ) async {
    if (fullHistory.isEmpty) {
      return MultiHorizonAlerts.empty();
    }

    // 1️⃣ Analyse long-terme avec TOUT l'historique
    final longTermAnalysis =
        await _trendService.analyzeLongTermTrends(fullHistory);

    // 2️⃣ Prévisions de fragilité multi-horizon
    final fragilityForecast =
        await _fragilityService.calculateFragilityForecast(
      fullHistory,
      profile,
    );

    // 3️⃣ Alertes préventives par horizon temporel
    final alerts6h = _generatePreventive6HourAlerts(fragilityForecast);
    final alerts24h =
        _generatePreventive24HourAlerts(fragilityForecast, longTermAnalysis);
    final alerts7d =
        _generatePreventive7DayAlerts(fragilityForecast, longTermAnalysis);

    // 4️⃣ Recommandations stratégiques basées sur l'analyse complète
    final strategicRecommendations = _generateStrategicRecommendations(
      fragilityForecast,
      longTermAnalysis,
    );

    return MultiHorizonAlerts(
      alerts6Hours: alerts6h,
      alerts24Hours: alerts24h,
      alerts7Days: alerts7d,
      fragilityForecast: fragilityForecast,
      longTermAnalysis: longTermAnalysis,
      strategicRecommendations: strategicRecommendations,
      generatedAt: DateTime.now(),
    );
  }

  /// Alertes préventives 6h (urgence imminente)
  List<PreventiveAlert> _generatePreventive6HourAlerts(
      FragilityForecast forecast) {
    final alerts = <PreventiveAlert>[];

    if (forecast.prediction6Hours.predictedLevel == FragilityLevel.critical) {
      alerts.add(PreventiveAlert(
        id: 'critical_6h_${DateTime.now().millisecondsSinceEpoch}',
        severity: AlertSeverity.critical,
        timeHorizon: '6 heures',
        title: '🚨 URGENCE IMMINENTE',
        message: 'Risque critique détecté dans les 6h prochaines',
        confidence: forecast.prediction6Hours.confidence,
        preventiveActions: [
          'ARRÊTER toute activité physique',
          'Mesurer SpO₂ toutes les heures',
          'Préparer médicaments d\'urgence',
          'Alerter contacts d\'urgence',
          'Ne pas rester seul(e)',
        ],
        riskFactors: forecast.prediction6Hours.riskFactors,
        estimatedOnset: DateTime.now().add(Duration(hours: 6)),
        worstCaseScenario: forecast.prediction6Hours.worstCaseScenario,
      ));
    }

    if (forecast.prediction6Hours.predictedLevel == FragilityLevel.elevated) {
      alerts.add(PreventiveAlert(
        id: 'elevated_6h_${DateTime.now().millisecondsSinceEpoch}',
        severity: AlertSeverity.high,
        timeHorizon: '6 heures',
        title: '⚠️ Vigilance renforcée requise',
        message: 'Dégradation probable dans les 6h',
        confidence: forecast.prediction6Hours.confidence,
        preventiveActions: [
          'Limiter efforts physiques',
          'Mesures toutes les 2h',
          'Rester dans environnement sûr',
          'Tenir médicaments à portée',
        ],
        riskFactors: forecast.prediction6Hours.riskFactors,
        estimatedOnset: DateTime.now().add(Duration(hours: 6)),
        worstCaseScenario: forecast.prediction6Hours.worstCaseScenario,
      ));
    }

    return alerts;
  }

  /// Alertes préventives 24h (planification quotidienne)
  List<PreventiveAlert> _generatePreventive24HourAlerts(
    FragilityForecast forecast,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final alerts = <PreventiveAlert>[];

    if (forecast.prediction24Hours.predictedLevel != FragilityLevel.stable) {
      final actions = <String>[];

      // Actions basées sur le niveau prédit
      if (forecast.prediction24Hours.predictedLevel ==
          FragilityLevel.critical) {
        actions.addAll([
          'Planifier journée repos complet',
          'Annuler rendez-vous non essentiels',
          'Mesures toutes les 4h demain',
          'Contact médecin recommandé',
        ]);
      } else {
        actions.addAll([
          'Adapter planning demain',
          'Privilégier activités légères',
          'Surveillance renforcée',
        ]);
      }

      // Actions spécifiques aux habitudes détectées
      if (!longTermAnalysis.hasInsufficientData) {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final tomorrowWeekday = tomorrow.weekday;

        if (longTermAnalysis.weeklyPatterns.spo2ByDay
            .containsKey(tomorrowWeekday)) {
          final worstDay = longTermAnalysis.weeklyPatterns.worstDay;
          if (tomorrowWeekday == worstDay) {
            actions
                .add('⚠️ Demain = votre jour le plus difficile habituellement');
          }
        }
      }

      alerts.add(PreventiveAlert(
        id: 'planning_24h_${DateTime.now().millisecondsSinceEpoch}',
        severity:
            forecast.prediction24Hours.predictedLevel == FragilityLevel.critical
                ? AlertSeverity.critical
                : AlertSeverity.medium,
        timeHorizon: '24 heures',
        title: 'Planification préventive demain',
        message: 'Adaptations recommandées pour demain',
        confidence: forecast.prediction24Hours.confidence,
        preventiveActions: actions,
        riskFactors: forecast.prediction24Hours.riskFactors,
        estimatedOnset: DateTime.now().add(Duration(hours: 24)),
        worstCaseScenario: forecast.prediction24Hours.worstCaseScenario,
      ));
    }

    return alerts;
  }

  /// Alertes préventives 7j (stratégie hebdomadaire)
  List<PreventiveAlert> _generatePreventive7DayAlerts(
    FragilityForecast forecast,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final alerts = <PreventiveAlert>[];

    // Alertes basées sur les tendances long-terme
    if (!longTermAnalysis.hasInsufficientData) {
      final trends = longTermAnalysis.longTermTrends;

      if (trends.spo2Trend < -1.0) {
        // Déclin significatif
        alerts.add(PreventiveAlert(
          id: 'longterm_decline_${DateTime.now().millisecondsSinceEpoch}',
          severity: AlertSeverity.high,
          timeHorizon: '7 jours',
          title: 'Déclin long-terme détecté',
          message: 'Tendance négative sur votre historique étendu',
          confidence: 0.8,
          preventiveActions: [
            'Consulter médecin cette semaine',
            'Réévaluer traitement actuel',
            'Optimiser environnement de vie',
            'Renforcer suivi quotidien',
          ],
          riskFactors: [
            'Déclin SpO₂ de ${trends.spo2Trend.toStringAsFixed(1)}%/semaine'
          ],
          estimatedOnset: DateTime.now().add(Duration(days: 7)),
          worstCaseScenario: forecast.prediction7Days.worstCaseScenario,
        ));
      }

      // Alertes basées sur les cycles récurrents
      for (var cycle in longTermAnalysis.recurringCycles) {
        if (cycle.similarity > 0.8 && cycle.pattern.contains('dégradation')) {
          alerts.add(PreventiveAlert(
            id: 'recurring_cycle_${cycle.lengthDays}d_${DateTime.now().millisecondsSinceEpoch}',
            severity: AlertSeverity.medium,
            timeHorizon: '${cycle.lengthDays} jours',
            title: 'Cycle défavorable prévu',
            message:
                'Habitude récurrente de ${cycle.lengthDays} jours détectée',
            confidence: cycle.similarity,
            preventiveActions: [
              'Préparer stratégie spécifique',
              'Adapter routine les jours concernés',
              'Surveillance préventive renforcée',
            ],
            riskFactors: [cycle.pattern],
            estimatedOnset:
                DateTime.now().add(Duration(days: cycle.lengthDays)),
            worstCaseScenario:
                'Risque de répétition du pattern de dégradation observé précédemment.',
          ));
        }
      }
    }

    return alerts;
  }

  /// Recommandations stratégiques basées sur l'analyse complète
  List<StrategicRecommendation> _generateStrategicRecommendations(
    FragilityForecast forecast,
    LongTermTrendAnalysis longTermAnalysis,
  ) {
    final recommendations = <StrategicRecommendation>[];

    // Stratégie basée sur les habitudes hebdomadaires
    if (!longTermAnalysis.hasInsufficientData) {
      final weeklyPattern = longTermAnalysis.weeklyPatterns;

      recommendations.add(StrategicRecommendation(
        category: 'Optimisation hebdomadaire',
        title: 'Adapter votre routine aux habitudes détectées',
        description: 'Votre meilleur jour: ${weeklyPattern.bestDayName}, '
            'votre jour le plus difficile: ${weeklyPattern.worstDayName}',
        actions: [
          'Planifier activités importantes les ${weeklyPattern.bestDayName}',
          'Repos prioritaire les ${weeklyPattern.worstDayName}',
          'Surveillance renforcée veilles de ${weeklyPattern.worstDayName}',
        ],
        evidence: 'Basé sur ${weeklyPattern.spo2ByDay.length} jours d\'analyse',
        isBestLever: weeklyPattern.worstDay == DateTime.now().weekday,
      ));

      // Stratégie basée sur les liens directs
      final correlations = longTermAnalysis.extendedCorrelations;
      if (correlations.spo2BreathingCorr.abs() > 0.6) {
        recommendations.add(StrategicRecommendation(
          category: 'Exercices ciblés',
          title: 'Lien direct SpO₂-Respiration détecté',
          description:
              'Vos paramètres sont ${correlations.spo2BreathingCorr > 0 ? "positivement" : "négativement"} liés',
          actions: [
            'Privilégier exercices respiratoires quotidiens',
            'Surveillance simultanée des deux paramètres',
            'Techniques de respiration lors de stress',
          ],
          evidence:
              'Analyse de lien: ${correlations.spo2BreathingCorr.toStringAsFixed(2)}',
          isBestLever:
              true, // La stabilisation respiratoire est souvent le meilleur levier
        ));
      }
    }

    return recommendations;
  }

  /// Convertit les TrendAlert en ModeleAlerte
  List<ModeleAlerte> _convertTrendAlertsToModeleAlerte(
      List<TrendAlert> trendAlerts) {
    return trendAlerts.map((trend) {
      TypeAlerte type;
      NiveauNotification niveau;
      int priorite;

      switch (trend.severity) {
        case 'high':
          type = TypeAlerte.critique;
          niveau = NiveauNotification.urgence;
          priorite = 90;
          break;
        case 'medium':
          type = TypeAlerte.ia;
          niveau = NiveauNotification.alerte;
          priorite = 70;
          break;
        default:
          type = TypeAlerte.ia;
          niveau = NiveauNotification.prevention;
          priorite = 50;
      }

      return ModeleAlerte(
        id: trend.id,
        titre: trend.title,
        description: trend.message,
        type: type,
        niveauPriorite: priorite,
        dateCreation: trend.timestamp,
        niveauNotification: niveau,
        recommandations: trend.actions,
        tags: ['prediction', 'tendance', trend.type],
        source: 'Moteur Prédictif IA v3.0',
        donneesMedicales: trend.metadata,
      );
    }).toList();
  }

  /// Crée une alerte basée sur le score de fragilité
  ModeleAlerte _createFragilityAlert(FragilityScore score) {
    TypeAlerte type;
    NiveauNotification niveau;
    int priorite;

    switch (score.level) {
      case FragilityLevel.critical:
        type = TypeAlerte.critique;
        niveau = NiveauNotification.urgence;
        priorite = 95;
        break;
      case FragilityLevel.elevated:
        type = TypeAlerte.ia;
        niveau = NiveauNotification.alerte;
        priorite = 75;
        break;
      default:
        type = TypeAlerte.ia;
        niveau = NiveauNotification.prevention;
        priorite = 50;
    }

    final factorsDescription =
        score.factors.map((f) => '• ${f.name}: ${f.explanation}').join('\n');

    return ModeleAlerte(
      id: 'fragility_${DateTime.now().millisecondsSinceEpoch}',
      titre: '${score.level.emoji} Score de fragilité: ${score.level.label}',
      description:
          'Votre score de fragilité est de ${score.value.toStringAsFixed(0)}/100.\n\n'
          'Facteurs contributifs:\n$factorsDescription',
      type: type,
      niveauPriorite: priorite,
      dateCreation: DateTime.now(),
      niveauNotification: niveau,
      recommandations: score.recommendations,
      tags: ['fragilite', 'score', score.level.name],
      source: 'Moteur Prédictif IA v3.0',
      donneesMedicales: {
        'fragility_score': score.value,
        'fragility_level': score.level.name,
        'factors_count': score.factors.length,
        'next_review_hours': score.nextReviewIn.inHours,
      },
    );
  }

  /// Génère un rapport de santé prédictif complet
  Future<String> generatePredictiveReport(
    PredictiveAnalysisResult result,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📊 RAPPORT PRÉDICTIF DE SANTÉ');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Généré le: ${_formatDateTime(result.analysisTimestamp)}');
    buffer.writeln();

    // Score de fragilité
    buffer.writeln('🎯 SCORE DE FRAGILITÉ');
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln(
        '${result.fragilityScore.level.emoji} ${result.fragilityScore.value.toStringAsFixed(0)}/100 - ${result.fragilityScore.level.label}');
    buffer.writeln(result.fragilityScore.level.description);
    buffer.writeln();

    if (result.fragilityScore.factors.isNotEmpty) {
      buffer.writeln('Facteurs de risque:');
      for (var factor in result.fragilityScore.factors) {
        buffer.writeln(
            '  • ${factor.name} (+${factor.contribution.toStringAsFixed(0)} pts)');
        buffer.writeln('    ${factor.explanation}');
      }
      buffer.writeln();
    }

    // Alertes de tendance
    if (result.trendAlerts.isNotEmpty) {
      buffer.writeln('⚠️ ALERTES PRÉDICTIVES (${result.trendAlerts.length})');
      buffer.writeln('───────────────────────────────────────');
      for (var alert in result.trendAlerts) {
        buffer.writeln('${_getSeverityEmoji(alert.severity)} ${alert.title}');
        buffer.writeln('  ${alert.message}');
        if (alert.preventionWindow != null) {
          buffer.writeln(
              '  ⏰ Fenêtre de prévention: ${alert.preventionWindow!.inDays} jours');
        }
        buffer.writeln();
      }
    }

    // Recommandations actionnables
    if (result.actionableRecommendations.isNotEmpty) {
      buffer.writeln(
          '✅ ACTIONS À PRENDRE (${result.actionableRecommendations.length})');
      buffer.writeln('───────────────────────────────────────');
      for (var rec in result.actionableRecommendations.take(5)) {
        buffer.writeln('${rec.isCritical ? '🚨' : '📋'} ${rec.action}');
        buffer.writeln('  ⏱️ ${rec.timeRemainingLabel}');
        buffer.writeln('  ✓ ${rec.successCriteria}');
        buffer.writeln();
      }
    }

    // Conseils de prévention
    if (result.preventionAdvice.isNotEmpty) {
      buffer.writeln(
          '💡 CONSEILS PERSONNALISÉS (${result.preventionAdvice.length})');
      buffer.writeln('───────────────────────────────────────');
      for (var advice in result.preventionAdvice) {
        buffer.writeln('${advice.title}');
        buffer.writeln('  ${advice.message}');
        buffer.writeln('  📅 ${advice.timing}');
        buffer.writeln();
      }
    }

    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  String _getSeverityEmoji(String severity) {
    switch (severity) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      default:
        return '🟢';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Résultat de l'analyse prédictive
class PredictiveAnalysisResult {
  final List<TrendAlert> trendAlerts;
  final FragilityScore fragilityScore;
  final List<PreventionAdvice> preventionAdvice;
  final List<ActionableRecommendation> actionableRecommendations;
  final List<ModeleAlerte> modeleAlertes;
  final DateTime analysisTimestamp;

  PredictiveAnalysisResult({
    required this.trendAlerts,
    required this.fragilityScore,
    required this.preventionAdvice,
    required this.actionableRecommendations,
    required this.modeleAlertes,
    required this.analysisTimestamp,
  });

  factory PredictiveAnalysisResult.empty() {
    return PredictiveAnalysisResult(
      trendAlerts: [],
      fragilityScore: FragilityScore(
        value: 0,
        level: FragilityLevel.stable,
        factors: [],
        nextReviewIn: Duration(days: 1),
        recommendations: ['Aucune donnée disponible'],
      ),
      preventionAdvice: [],
      actionableRecommendations: [],
      modeleAlertes: [],
      analysisTimestamp: DateTime.now(),
    );
  }

  bool get hasHighPriorityAlerts =>
      trendAlerts.any((a) => a.severity == 'high') ||
      fragilityScore.level == FragilityLevel.critical;

  bool get requiresImmediateAction =>
      fragilityScore.value >= 70 ||
      actionableRecommendations.any((r) => r.isCritical);
}
