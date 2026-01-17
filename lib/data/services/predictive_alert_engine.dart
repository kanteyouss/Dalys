import '../models/health_data.dart';
import '../models/patient_risk_profile.dart';
import '../models/trend_models.dart';
import '../models/fragility_models.dart';
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

    final factorsDescription = score.factors
        .map((f) => '• ${f.name}: ${f.explanation}')
        .join('\n');

    return ModeleAlerte(
      id: 'fragility_${DateTime.now().millisecondsSinceEpoch}',
      titre: '${score.level.emoji} Score de fragilité: ${score.level.label}',
      description: 'Votre score de fragilité est de ${score.value.toStringAsFixed(0)}/100.\n\n'
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
        buffer.writeln(
            '${rec.isCritical ? '🚨' : '📋'} ${rec.action}');
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
