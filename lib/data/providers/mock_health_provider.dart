import 'dart:async';
import 'dart:math';
import '../models/health_data.dart';
import '../models/alert_model.dart';
import '../../core/enums/app_enums.dart';

class MockHealthProvider {
  final Random _random = Random();
  Timer? _timer;

  static final MockHealthProvider _instance = MockHealthProvider._internal();
  factory MockHealthProvider() => _instance;
  MockHealthProvider._internal();

  Stream<HealthData> getHealthDataStream() {
    return Stream.periodic(
      const Duration(seconds: 25),
      (_) => _generateMockData(),
    );
  }

  // Génération de données simulées réalistes
  HealthData _generateMockData() {
    // Simulation de données réalistes avec variations
    // 20% de chance de générer une valeur critique (pour tester l'IA)
    final criticalChance = _random.nextDouble();
    
    int spo2;
    int breathingRate;
    double pef;
    
    if (criticalChance < 0.10) {
      // 10% - État TRÈS CRITIQUE
      spo2 = 85 + _random.nextInt(5); // 85-89%
      breathingRate = 25 + _random.nextInt(6); // 25-30 bpm
      pef = 150.0 + _random.nextInt(100); // 150-250 L/min
    } else if (criticalChance < 0.25) {
      // 15% - État critique modéré
      spo2 = 90 + _random.nextInt(4); // 90-93%
      breathingRate = 21 + _random.nextInt(5); // 21-25 bpm
      pef = 250.0 + _random.nextInt(100); // 250-350 L/min
    } else {
      // 75% - État normal
      spo2 = 95 + _random.nextInt(5); // 95-99%
      breathingRate = 14 + _random.nextInt(7); // 14-20 bpm
      pef = 350.0 + _random.nextInt(150); // 350-500 L/min
    }
    
    final temperature = 36.5 + _random.nextDouble(); // 36.5-37.5 °C
    final humidity = 40.0 + _random.nextInt(40); // 40-80%
    final envTemperature = 20.0 + _random.nextInt(10); // 20-30 °C

    final symptoms = <String>[];
    final allSymptoms = [
      'toux',
      'fatigue',
      'essoufflement',
      'douleur thoracique',
      'oppression'
    ];

    // 30% de chance d'avoir des symptômes
    if (_random.nextDouble() < 0.3) {
      final numSymptoms = 1 + _random.nextInt(2); // 1-2 symptômes
      final shuffled = List.from(allSymptoms)..shuffle(_random);
      symptoms.addAll(shuffled.take(numSymptoms).cast<String>());
    }

    // Déterminer le niveau de risque basé sur les valeurs
    RiskLevel riskLevel = RiskLevel.low;

    // Conditions de risque élevé
    if (spo2 < 92 ||
        breathingRate > 24 ||
        pef < 250 ||
        symptoms.contains('essoufflement')) {
      riskLevel = RiskLevel.high;
    }
    // Conditions de risque modéré
    else if (spo2 < 95 ||
        breathingRate > 20 ||
        pef < 350 ||
        symptoms.isNotEmpty) {
      riskLevel = RiskLevel.medium;
    }

    return HealthData(
      date: DateTime.now(),
      spo2: spo2,
      breathingRate: breathingRate,
      pef: pef,
      temperature: temperature,
      humidity: humidity,
      envTemperature: envTemperature,
      symptoms: symptoms,
      riskLevel: riskLevel,
    );
  }

  // Génération de données réalistes (méthode publique)
  HealthData generateRealisticHealthData() {
    return _generateMockData();
  }

  // Données historiques (7 derniers jours)
  List<HealthData> getHistoricalData({int days = 7}) {
    final data = <HealthData>[];
    for (int i = days; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));

      // Variation progressive des données pour simuler une évolution
      final baseSpo2 = 96 + (sin(i * 0.5) * 2).round();
      final baseBreathingRate = 18 + (cos(i * 0.3) * 2).round();
      final basePef = 400 + (sin(i * 0.4) * 50);
      final baseTemp = 37.0 + (sin(i * 0.2) * 0.5);

      data.add(HealthData(
        date: date,
        spo2: (baseSpo2 + _random.nextInt(3) - 1).clamp(90, 99),
        breathingRate:
            (baseBreathingRate + _random.nextInt(3) - 1).clamp(12, 25),
        pef: (basePef + _random.nextInt(50) - 25).clamp(250, 500),
        temperature: (baseTemp + _random.nextDouble() - 0.5).clamp(36.0, 39.0),
        humidity: (60.0 + _random.nextInt(20)).toDouble(),
        envTemperature: (25.0 + _random.nextInt(5)).toDouble(),
        symptoms: _getRandomSymptoms(),
        riskLevel: RiskLevel.values[_random.nextInt(3)],
      ));
    }
    return data;
  }

  // Génération d'alertes simulées
  List<AlertModel> getMockAlerts({int count = 10}) {
    final alerts = <AlertModel>[];
    final alertTemplates = [
      {
        'type': AlertType.aiPrediction,
        'title': 'Prédiction IA',
        'messages': [
          'Risque élevé de crise respiratoire dans les 24h',
          'Votre état respiratoire nécessite une attention',
          'Tendance à la dégradation détectée'
        ],
        'recommendations': [
          'Prenez votre traitement préventif',
          'Évitez les activités physiques intenses',
          'Consultez votre médecin si les symptômes persistent'
        ]
      },
      {
        'type': AlertType.environmental,
        'title': 'Alerte environnementale',
        'messages': [
          'Pic de pollution détecté à Abidjan',
          'Taux de pollen élevé aujourd\'hui',
          'Qualité de l\'air dégradée'
        ],
        'recommendations': [
          'Limitez vos activités extérieures',
          'Gardez les fenêtres fermées',
          'Portez un masque si vous sortez'
        ]
      },
      {
        'type': AlertType.healthAnomaly,
        'title': 'Anomalie détectée',
        'messages': [
          'Saturation en oxygène anormalement basse',
          'Fréquence respiratoire élevée détectée',
          'Débit de pointe en baisse'
        ],
        'recommendations': [
          'Prenez vos médicaments',
          'Reposez-vous',
          'Contactez votre médecin'
        ]
      }
    ];

    for (int i = 0; i < count; i++) {
      final template = alertTemplates[_random.nextInt(alertTemplates.length)];
      final messages = template['messages'] as List<String>;
      final recommendations = template['recommendations'] as List<String>;

      alerts.add(AlertModel(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch + i}',
        title: template['title'] as String,
        message: messages[_random.nextInt(messages.length)],
        type: template['type'] as AlertType,
        severity: RiskLevel.values[_random.nextInt(3)],
        timestamp:
            DateTime.now().subtract(Duration(hours: _random.nextInt(72))),
        recommendation:
            recommendations[_random.nextInt(recommendations.length)],
        isRead: _random.nextBool(),
      ));
    }

    // Trier par date (plus récent en premier)
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }

  // Génération d'une alerte en temps réel
  AlertModel generateRealtimeAlert() {
    final alerts = getMockAlerts(count: 1);
    return alerts.first.copyWith(
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  List<String> _getRandomSymptoms() {
    final allSymptoms = [
      'toux',
      'fatigue',
      'essoufflement',
      'douleur thoracique',
      'oppression'
    ];
    final symptoms = <String>[];

    // 40% de chance d'avoir des symptômes
    if (_random.nextDouble() < 0.4) {
      for (final symptom in allSymptoms) {
        if (_random.nextDouble() < 0.3) {
          symptoms.add(symptom);
        }
      }
    }
    return symptoms;
  }

  // Données environnementales simulées
  Map<String, dynamic> getEnvironmentalData() {
    return {
      'air_quality_index': 50 + _random.nextInt(100), // 50-150
      'pollen_count': _random.nextInt(5), // 0-4 (faible à élevé)
      'temperature': 25 + _random.nextInt(10), // 25-35°C
      'humidity': 60 + _random.nextInt(30), // 60-90%
      'location': 'Abidjan, Côte d\'Ivoire',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _timer?.cancel();
  }
}
