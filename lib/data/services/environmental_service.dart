import 'dart:convert';
import 'package:http/http.dart' as http;

class EnvironmentalData {
  final double temperature;
  final double humidity;
  final int aqi; // Air Quality Index
  final String mainPollutant;
  final String description;

  EnvironmentalData({
    required this.temperature,
    required this.humidity,
    required this.aqi,
    required this.mainPollutant,
    required this.description,
  });
}

class EnvironmentalService {
  static final EnvironmentalService _instance =
      EnvironmentalService._internal();
  factory EnvironmentalService() => _instance;
  EnvironmentalService._internal();

  // API Keys (Placeholders)
  final String _openWeatherKey = "YOUR_OPENWEATHER_KEY";
  final String _iqAirKey = "YOUR_IQAIR_KEY";

  Future<EnvironmentalData> getLatestData(double lat, double lon) async {
    try {
      // In a real app, we would call the APIs here.
      // For now, we simulate the data or use a mock if keys are missing.

      // Simulation of network delay
      await Future.delayed(const Duration(milliseconds: 500));

      return EnvironmentalData(
        temperature: 22.5,
        humidity: 45.0,
        aqi: 42, // Good
        mainPollutant: "p2",
        description: "Ciel dégagé, qualité de l'air bonne.",
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Retourne un niveau de risque basé sur l'AQI
  String getAqiRiskLevel(int aqi) {
    if (aqi <= 50) return "Bon";
    if (aqi <= 100) return "Modéré";
    if (aqi <= 150) return "Mauvais pour les groupes sensibles";
    if (aqi <= 200) return "Mauvais";
    if (aqi <= 300) return "Très mauvais";
    return "Dangereux";
  }

  /// Alias pour compatibilité avec les nouveaux services
  Future<EnvironmentalData?> getCurrentData() async {
    try {
      // Coordonnées par défaut (Abidjan, Côte d'Ivoire)
      return await getLatestData(5.345317, -4.024429);
    } catch (e) {
      return null;
    }
  }
}
