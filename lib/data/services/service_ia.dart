import 'dart:async';
import 'dart:math';
import '../models/health_data.dart';
import '../models/modele_suggestion.dart';
import '../../core/enums/app_enums.dart';
import 'environmental_service.dart';

/// Service simulant l'API Python pour l'intelligence artificielle
/// Analyse les données de santé et génère des suggestions personnalisées
class ServiceIA {
  static final ServiceIA _instance = ServiceIA._internal();
  factory ServiceIA() => _instance;
  ServiceIA._internal();

  final Random _random = Random();
  final EnvironmentalService _envService = EnvironmentalService();

  /// Simule l'appel à l'API de prédiction
  /// Prend en entrée les données de santé actuelles et retourne une liste de suggestions
  Future<List<Suggestion>> getSuggestions(HealthData healthData,
      {EnvironmentalData? envData}) async {
    // Simulation de latence réseau
    await Future.delayed(const Duration(milliseconds: 800));

    final suggestions = <Suggestion>[];

    // 1. Analyse basée sur les données vitales (Règles expertes)
    // ... (existing logic for vital signs)

    // 2. Analyse basée sur l'environnement réel
    if (envData != null) {
      if (envData.aqi > 100) {
        suggestions.add(Suggestion(
          id: 'env_aqi_high_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Qualité de l\'air dégradée',
          description:
              'L\'indice de qualité de l\'air est de ${envData.aqi} (${_envService.getAqiRiskLevel(envData.aqi)}). Évitez les activités physiques en extérieur.',
          type: TypeSuggestion.prevention,
          timestamp: DateTime.now(),
        ));
      }

      if (envData.humidity > 70) {
        suggestions.add(Suggestion(
          id: 'env_hum_high_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Humidité élevée',
          description:
              'L\'humidité est élevée (${envData.humidity}%). Cela peut favoriser les moisissures, soyez vigilant si vous êtes asthmatique.',
          type: TypeSuggestion.prevention,
          timestamp: DateTime.now(),
        ));
      }
    } else {
      // Fallback sur la simulation si pas de données réelles
      final isHighPollen = _random.nextBool();
      if (isHighPollen) {
        suggestions.add(Suggestion(
          id: 'env_pollen_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Risque allergique (Simulé)',
          description:
              'Le taux de pollen est élevé aujourd\'hui. Pensez à votre traitement.',
          type: TypeSuggestion.prevention,
          timestamp: DateTime.now(),
        ));
      }
    }

    // ... (rest of the logic)
    return suggestions;
  }
}
