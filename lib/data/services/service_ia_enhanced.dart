import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/health_data.dart';
import '../models/fragility_models.dart';
import '../models/modele_suggestion.dart';
import '../models/patient_risk_profile.dart';
import '../../core/enums/app_enums.dart';
import 'environmental_service.dart';
import 'predictive_alert_engine.dart';
import 'database_service.dart';

/// Service IA AMÉLIORÉ avec capacités prédictives
/// Remplace la logique réactive par une approche anticipative
class ServiceIAEnhanced {
  static final ServiceIAEnhanced _instance = ServiceIAEnhanced._internal();
  factory ServiceIAEnhanced() => _instance;
  ServiceIAEnhanced._internal();

  final EnvironmentalService _envService = EnvironmentalService();
  final PredictiveAlertEngine _predictiveEngine = PredictiveAlertEngine();
  final DatabaseService _dbService = DatabaseService();

  /// Génère des suggestions PRÉDICTIVES au lieu de réactives
  Future<List<Suggestion>> getPredictiveSuggestions(
    HealthData currentData, {
    EnvironmentalData? envData,
    required int userId,
  }) async {
    final suggestions = <Suggestion>[];

    // 1️⃣ Récupérer le profil de risque du patient
    final profile = await _getOrCreatePatientProfile(userId);

    // 2️⃣ Récupérer l'historique (14 derniers jours)
    final history = await _getHealthHistory(userId, days: 14);
    
    if (history.isEmpty) {
      history.add(currentData); // Au moins la donnée actuelle
    }

    // 3️⃣ Générer l'analyse prédictive complète
    final predictiveResult = await _predictiveEngine.generatePredictiveAlerts(
      profile,
      history,
    );

    // 4️⃣ Convertir les conseils de prévention en suggestions
    for (var advice in predictiveResult.preventionAdvice) {
      suggestions.add(Suggestion(
        id: advice.id,
        title: advice.title,
        description: '${advice.message}\n\n📊 ${advice.evidence}\n⏰ ${advice.timing}',
        type: TypeSuggestion.prevention,
        timestamp: advice.timestamp,
      ));
    }

    // 5️⃣ Convertir les recommandations actionnables en suggestions
    for (var rec in predictiveResult.actionableRecommendations.take(3)) {
      suggestions.add(Suggestion(
        id: rec.id,
        title: '${rec.isCritical ? '🚨' : '✅'} ${rec.category.toUpperCase()}',
        description: '${rec.action}\n\n'
            '⏱️ ${rec.timeRemainingLabel}\n'
            '✓ Résultat attendu: ${rec.successCriteria}',
        type: rec.isCritical ? TypeSuggestion.alert : TypeSuggestion.prevention,
        timestamp: DateTime.now(),
      ));
    }

    // 6️⃣ Ajouter suggestion basée sur le score de fragilité
    final fragilityScore = predictiveResult.fragilityScore;
    if (fragilityScore.value >= 40) {
      suggestions.add(Suggestion(
        id: 'fragility_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_getFragilityEmoji(fragilityScore.level)} État de santé: ${_getFragilityLevelLabel(fragilityScore.level)}',
        description: 'Votre score de fragilité est de ${fragilityScore.value.toStringAsFixed(0)}/100.\n\n'
            '${_getFragilityDescription(fragilityScore.level)}\n\n'
            'Principaux facteurs:\n${fragilityScore.factors.take(2).map((f) => '• ${f.name}').join('\n')}',
        type: fragilityScore.level == FragilityLevel.critical
            ? TypeSuggestion.alert
            : TypeSuggestion.prevention,
        timestamp: DateTime.now(),
      ));
    }

    // 7️⃣ Ajouter suggestions environnementales (si données disponibles)
    if (envData != null) {
      final envSuggestions = _getEnvironmentalSuggestions(envData, profile);
      suggestions.addAll(envSuggestions);
    }

    // 8️⃣ Sauvegar les alertes en base de données
    await _savePredictiveAlertsToDatabase(userId, predictiveResult);

    return suggestions;
  }

  /// Suggestions environnementales personnalisées
  List<Suggestion> _getEnvironmentalSuggestions(
    EnvironmentalData envData,
    PatientRiskProfile profile,
  ) {
    final suggestions = <Suggestion>[];

    // Vérifier les triggers personnels du patient
    for (var trigger in profile.triggers) {
      if (trigger.type == 'pollution' && envData.aqi > trigger.threshold) {
        suggestions.add(Suggestion(
          id: 'env_trigger_${DateTime.now().millisecondsSinceEpoch}',
          title: '🚨 VOTRE déclencheur personnel activé',
          description: 'Pollution: ${envData.aqi} (votre seuil: ${trigger.threshold})\n\n'
              'Selon votre historique, cela déclenche une réaction dans ${trigger.delayHours}h.\n\n'
              '${trigger.preventiveMedication != null ? 'Action immédiate: ${trigger.preventiveMedication}' : ''}',
          type: TypeSuggestion.alert,
          timestamp: DateTime.now(),
        ));
      }
    }

    // Suggestions générales environnementales
    if (envData.aqi > 100) {
      suggestions.add(Suggestion(
        id: 'env_aqi_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Qualité de l\'air dégradée',
        description: 'AQI: ${envData.aqi} (${_envService.getAqiRiskLevel(envData.aqi)})\n\n'
            'Recommandations:\n'
            '• Restez à l\'intérieur\n'
            '• Fenêtres fermées\n'
            '• Portez un masque si sortie nécessaire',
        type: TypeSuggestion.prevention,
        timestamp: DateTime.now(),
      ));
    }

    return suggestions;
  }

  /// Récupère ou crée le profil de risque du patient
  Future<PatientRiskProfile> _getOrCreatePatientProfile(int userId) async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'patient_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) {
      // Créer un profil par défaut
      final defaultProfile = PatientRiskProfile.createDefault(userId);
      
      // Sauvegarder en base
      await db.insert('patient_profiles', {
        'user_id': userId,
        'baseline_spo2': defaultProfile.baselineSpo2,
        'baseline_breathing_rate': defaultProfile.baselineBreathingRate,
        'baseline_pef': defaultProfile.baselinePef,
        'patterns': '[]',
        'triggers': '[]',
        'morning_risk': '{"period":"morning","risk_score":25}',
        'afternoon_risk': '{"period":"afternoon","risk_score":20}',
        'evening_risk': '{"period":"evening","risk_score":30}',
        'night_risk': '{"period":"night","risk_score":35}',
        'last_updated': DateTime.now().toIso8601String(),
        'days_analyzed': 0,
      });
      
      return defaultProfile;
    }

    // TODO: Parser le résultat de la base
    // Pour l'instant, retourner le profil par défaut
    return PatientRiskProfile.createDefault(userId);
  }

  /// Récupère l'historique de santé
  Future<List<HealthData>> _getHealthHistory(int userId, {int days = 14}) async {
    final db = await _dbService.database;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final results = await db.query(
      'health_data',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
      orderBy: 'date ASC',
    );

    return results.map((row) {
      return HealthData(
        userId: row['user_id'] as int,
        date: DateTime.parse(row['date'] as String),
        spo2: row['spo2'] as int,
        breathingRate: row['breathing_rate'] as int,
        pef: (row['pef'] as num).toDouble(),
        temperature: row['temperature'] != null ? (row['temperature'] as num).toDouble() : null,
        humidity: row['humidity'] != null ? (row['humidity'] as num).toDouble() : null,
        envTemperature: row['env_temperature'] != null ? (row['env_temperature'] as num).toDouble() : null,
        symptoms: row['symptoms'] != null ? (row['symptoms'] as String).split(',') : [],
        riskLevel: RiskLevel.values.firstWhere(
          (e) => e.name == row['risk_level'],
          orElse: () => RiskLevel.low,
        ),
      );
    }).toList();
  }

  /// Sauvegarde les alertes prédictives en base
  Future<void> _savePredictiveAlertsToDatabase(
    int userId,
    PredictiveAnalysisResult result,
  ) async {
    final db = await _dbService.database;

    // Sauvegarder les alertes de tendance
    for (var alert in result.trendAlerts) {
      await db.insert(
        'trend_alerts',
        {
          'id': alert.id,
          'user_id': userId,
          'type': alert.type,
          'severity': alert.severity,
          'title': alert.title,
          'message': alert.message,
          'actions': alert.actions.join('|||'),
          'prevention_window_hours': alert.preventionWindow?.inHours,
          'timestamp': alert.timestamp.toIso8601String(),
          'metadata': alert.metadata.toString(),
          'is_read': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Sauvegarder le score de fragilité
    await db.insert('fragility_scores', {
      'user_id': userId,
      'value': result.fragilityScore.value,
      'level': result.fragilityScore.level.name,
      'factors': result.fragilityScore.factors.map((f) => f.toJson()).toString(),
      'next_review_hours': result.fragilityScore.nextReviewIn.inHours,
      'recommendations': result.fragilityScore.recommendations.join('|||'),
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Sauvegarder les recommandations actionnables
    for (var rec in result.actionableRecommendations) {
      await db.insert(
        'actionable_recommendations',
        {
          'id': rec.id,
          'user_id': userId,
          'action': rec.action,
          'deadline': rec.deadline.toIso8601String(),
          'estimated_duration_minutes': rec.estimatedDuration.inMinutes,
          'is_critical': rec.isCritical ? 1 : 0,
          'success_criteria': rec.successCriteria,
          'category': rec.category,
          'priority': rec.priority,
          'completed': 0,
          'completed_at': null,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Helper pour obtenir le label du niveau de fragilité
  String _getFragilityLevelLabel(FragilityLevel level) {
    switch (level) {
      case FragilityLevel.stable:
        return 'Faible';
      case FragilityLevel.moderate:
        return 'Modérée';
      case FragilityLevel.elevated:
        return 'Élevée';
      case FragilityLevel.critical:
        return 'Critique';
    }
  }

  /// Helper pour obtenir l'emoji du niveau de fragilité
  String _getFragilityEmoji(FragilityLevel level) {
    switch (level) {
      case FragilityLevel.stable:
        return '✅';
      case FragilityLevel.moderate:
        return '⚠️';
      case FragilityLevel.elevated:
        return '🔶';
      case FragilityLevel.critical:
        return '🚨';
    }
  }

  /// Helper pour obtenir la description du niveau de fragilité
  String _getFragilityDescription(FragilityLevel level) {
    switch (level) {
      case FragilityLevel.stable:
        return 'État stable - Continuez vos bonnes habitudes';
      case FragilityLevel.moderate:
        return 'Vigilance normale - Surveillance recommandée';
      case FragilityLevel.elevated:
        return 'État fragile - Surveillance renforcée nécessaire';
      case FragilityLevel.critical:
        return 'État pré-critique - Action immédiate requise';
    }
  }
}
