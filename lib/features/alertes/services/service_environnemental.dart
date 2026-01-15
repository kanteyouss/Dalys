import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dalys/data/models/modele_alerte.dart';

/// Service pour la gestion des alertes environnementales
/// Intègre plusieurs APIs : AirVisual, OpenWeatherMap, Breezometer
class ServiceEnvironnemental {
  /// Instance singleton
  static final ServiceEnvironnemental _instance = ServiceEnvironnemental._internal();
  factory ServiceEnvironnemental() => _instance;
  ServiceEnvironnemental._internal();

  /// URLs des APIs (à configurer avec de vraies clés API)
  static const String _airVisualUrl = 'http://api.airvisual.com/v2';
  static const String _openWeatherUrl = 'http://api.openweathermap.org/data/2.5';
  static const String _breezometerUrl = 'https://api.breezometer.com/air-quality/v2';
  
  /// Clés API (à configurer depuis les variables d'environnement)
  static const String _airVisualKey = 'DEMO_KEY';
  static const String _openWeatherKey = 'DEMO_KEY';
  static const String _breezometerKey = 'DEMO_KEY';
  
  /// Cache des dernières données
  Map<String, dynamic>? _dernieresdonneesEnv;
  DateTime? _derniereMiseAJourEnv;
  
  /// Indique si le service est en mode simulation
  bool _modeSimulation = true;
  
  /// Position actuelle
  Position? _positionActuelle;

  /// Active ou désactive le mode simulation
  void configurerModeSimulation(bool simulation) {
    _modeSimulation = simulation;
    debugPrint('🌍 Service environnemental configuré en mode ${simulation ? 'simulation' : 'production'}');
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position?> _obtenirPosition() async {
    if (_positionActuelle != null) return _positionActuelle;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Service de localisation désactivé');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Permission de localisation refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Permission de localisation définitivement refusée');
        return null;
      }

      _positionActuelle = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      debugPrint('📍 Position obtenue: ${_positionActuelle!.latitude}, ${_positionActuelle!.longitude}');
      return _positionActuelle;
      
    } catch (erreur) {
      debugPrint('❌ Erreur localisation: $erreur');
      return null;
    }
  }

  /// Récupère les alertes environnementales
  Future<List<ModeleAlerte>> obtenirAlertesEnvironnementales() async {
    if (_modeSimulation) {
      return await _simulerAlertesEnvironnementales();
    }

    try {
      final position = await _obtenirPosition();
      if (position == null) {
        debugPrint('⚠️ Position non disponible, utilisation du mode simulation');
        return await _simulerAlertesEnvironnementales();
      }

      final alertes = <ModeleAlerte>[];
      
      // Récupérer données de qualité de l'air
      final donneesAir = await _obtenirQualiteAir(position);
      if (donneesAir != null) {
        alertes.addAll(_analyserQualiteAir(donneesAir));
      }
      
      // Récupérer données météorologiques
      final donneesMeteo = await _obtenirDonneesMeteo(position);
      if (donneesMeteo != null) {
        alertes.addAll(_analyserDonneesMeteo(donneesMeteo));
      }
      
      // Mettre à jour le cache
      _dernieresdonneesEnv = {
        'air_quality': donneesAir,
        'weather': donneesMeteo,
        'position': {
          'lat': position.latitude,
          'lon': position.longitude,
        },
      };
      _derniereMiseAJourEnv = DateTime.now();
      
      debugPrint('🌍 ${alertes.length} alertes environnementales générées');
      return alertes;
      
    } catch (erreur) {
      debugPrint('❌ Erreur service environnemental: $erreur');
      return await _simulerAlertesEnvironnementales();
    }
  }

  /// Récupère les données de qualité de l'air (simulation d'API)
  Future<Map<String, dynamic>?> _obtenirQualiteAir(Position position) async {
    // TODO: Implémenter les vrais appels API
    /*
    final url = '$_airVisualUrl/city/coordinates?lat=${position.latitude}&lon=${position.longitude}&key=$_airVisualKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    */
    
    // Simulation pour la démonstration
    await Future.delayed(const Duration(milliseconds: 500));
    return _simulerDonneesQualiteAir();
  }

  /// Récupère les données météorologiques (simulation d'API)
  Future<Map<String, dynamic>?> _obtenirDonneesMeteo(Position position) async {
    // TODO: Implémenter les vrais appels API
    /*
    final url = '$_openWeatherUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_openWeatherKey&units=metric';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    */
    
    // Simulation pour la démonstration
    await Future.delayed(const Duration(milliseconds: 500));
    return _simulerDonneesMeteo();
  }

  /// Simule les alertes environnementales
  Future<List<ModeleAlerte>> _simulerAlertesEnvironnementales() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final alertes = <ModeleAlerte>[];
    final maintenant = DateTime.now();
    final heure = maintenant.hour;
    
    // Simulation d'un pic de pollution matinal (7h-9h) ou de soirée (17h-19h)
    if ((heure >= 7 && heure <= 9) || (heure >= 17 && heure <= 19)) {
      alertes.add(ModeleAlerte(
        id: 'env_pollution_${maintenant.millisecondsSinceEpoch}',
        titre: 'Pic de pollution détecté',
        description: 'La qualité de l\'air à Abidjan est dégradée (AQI: 125). '
                    'Risque accru pour les personnes souffrant de problèmes respiratoires.',
        type: TypeAlerte.environnementale,
        niveauPriorite: 80,
        dateCreation: maintenant,
        donneesMedicales: {
          'aqi': 125,
          'pm2_5': 65.4,
          'pm10': 89.2,
          'no2': 45.1,
          'o3': 78.3,
          'localisation': 'Abidjan, Côte d\'Ivoire',
          'source_pollution': 'trafic_routier',
        },
        recommandations: [
          'Évitez les activités extérieures intenses',
          'Gardez les fenêtres fermées',
          'Portez un masque anti-pollution si vous sortez',
          'Utilisez un purificateur d\'air à l\'intérieur',
        ],
        tags: ['environnement', 'pollution', 'air', 'aqi'],
        source: 'AirVisual API v2',
      ));
    }
    
    // Simulation d'alerte pollen (saison sèche : Novembre-Février)
    final mois = maintenant.month;
    if (mois >= 11 || mois <= 2) {
      alertes.add(ModeleAlerte(
        id: 'env_pollen_${maintenant.millisecondsSinceEpoch}',
        titre: 'Taux de pollen élevé',
        description: 'Les pollens d\'arbres sont particulièrement présents aujourd\'hui. '
                    'Risque d\'aggravation des symptômes allergiques et respiratoires.',
        type: TypeAlerte.environnementale,
        niveauPriorite: 60,
        dateCreation: maintenant,
        donneesMedicales: {
          'pollen_index': 4, // Sur une échelle de 0-5
          'dominant_pollen': 'arbres',
          'types_pollen': ['acacia', 'manguier', 'kapokier'],
          'vent_vitesse': 15.2, // km/h
          'humidite': 35, // %
        },
        recommandations: [
          'Prenez vos antihistaminiques si prescrits',
          'Évitez les sorties tôt le matin',
          'Gardez les fenêtres fermées',
          'Douchez-vous avant de vous coucher',
        ],
        tags: ['environnement', 'pollen', 'allergie', 'saison_seche'],
        source: 'Service Météorologique',
      ));
    }
    
    // Simulation d'alerte poussière (Harmattan : Décembre-Février)
    if (mois >= 12 || mois <= 2) {
      alertes.add(ModeleAlerte(
        id: 'env_harmattan_${maintenant.millisecondsSinceEpoch}',
        titre: 'Alerte Harmattan',
        description: 'Vents chargés de poussière du Sahara. Visibilité réduite et '
                    'risque d\'irritation des voies respiratoires.',
        type: TypeAlerte.environnementale,
        niveauPriorite: 70,
        dateCreation: maintenant,
        donneesMedicales: {
          'visibilite': 2.5, // km
          'particules_dust': 150, // µg/m³
          'vent_direction': 'Nord-Est',
          'vent_vitesse': 25.8, // km/h
          'humidite': 15, // %
          'temperature': 28, // °C
        },
        recommandations: [
          'Portez un masque ou un foulard sur le nez',
          'Hydratez-vous régulièrement',
          'Évitez les activités extérieures',
          'Utilisez des gouttes oculaires si nécessaire',
        ],
        tags: ['environnement', 'harmattan', 'poussiere', 'sahara'],
        source: 'SODEXAM Météo',
      ));
    }
    
    debugPrint('🌍 ${alertes.length} alertes environnementales simulées');
    return alertes;
  }

  /// Simule les données de qualité de l'air
  Map<String, dynamic> _simulerDonneesQualiteAir() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return {
      'status': 'success',
      'data': {
        'city': 'Abidjan',
        'state': 'Lagunes',
        'country': 'Côte d\'Ivoire',
        'current': {
          'pollution': {
            'ts': DateTime.now().toIso8601String(),
            'aqius': 80 + (random % 50), // AQI US (50-150)
            'mainus': 'p2', // PM2.5
            'aqicn': 75 + (random % 45), // AQI Chine
            'maincn': 'p2',
          },
          'weather': {
            'ts': DateTime.now().toIso8601String(),
            'tp': 28 + (random % 8), // Température
            'pr': 1013 - (random % 20), // Pression
            'hu': 60 + (random % 30), // Humidité
            'ws': 3.5 + (random % 5), // Vitesse vent
            'wd': 180 + (random % 180), // Direction vent
            'ic': '01d' // Code icône météo
          }
        }
      }
    };
  }

  /// Simule les données météorologiques
  Map<String, dynamic> _simulerDonneesMeteo() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return {
      'coord': {'lon': -4.0267, 'lat': 5.3364}, // Abidjan
      'weather': [
        {
          'id': 800,
          'main': 'Clear',
          'description': 'clear sky',
          'icon': '01d'
        }
      ],
      'base': 'stations',
      'main': {
        'temp': 28.5 + (random % 6),
        'feels_like': 32.1 + (random % 8),
        'temp_min': 26.0 + (random % 4),
        'temp_max': 34.0 + (random % 6),
        'pressure': 1013 - (random % 15),
        'humidity': 65 + (random % 25),
      },
      'visibility': 8000 + (random % 2000),
      'wind': {
        'speed': 3.2 + (random % 3),
        'deg': 180 + (random % 180),
      },
      'dt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'name': 'Abidjan',
    };
  }

  /// Analyse les données de qualité de l'air et génère des alertes
  List<ModeleAlerte> _analyserQualiteAir(Map<String, dynamic> donnees) {
    final alertes = <ModeleAlerte>[];
    
    // Extraire l'AQI
    final pollution = donnees['data']?['current']?['pollution'];
    if (pollution != null) {
      final aqi = pollution['aqius'] as int? ?? 50;
      
      if (aqi > 100) { // Malsain pour les groupes sensibles
        alertes.add(ModeleAlerte(
          id: 'aqi_${DateTime.now().millisecondsSinceEpoch}',
          titre: 'Qualité de l\'air dégradée',
          description: 'L\'indice de qualité de l\'air est de $aqi. '
                      'L\'air peut être malsain pour les personnes sensibles.',
          type: TypeAlerte.environnementale,
          niveauPriorite: aqi > 150 ? 85 : 70,
          dateCreation: DateTime.now(),
          donneesMedicales: {
            'aqi': aqi,
            'source': 'AirVisual',
            'polluant_principal': pollution['mainus'],
          },
          recommandations: _obtenirRecommandationsAQI(aqi),
          tags: ['environnement', 'aqi', 'pollution'],
          source: 'AirVisual API',
        ));
      }
    }
    
    return alertes;
  }

  /// Analyse les données météorologiques et génère des alertes
  List<ModeleAlerte> _analyserDonneesMeteo(Map<String, dynamic> donnees) {
    final alertes = <ModeleAlerte>[];
    
    final main = donnees['main'];
    if (main != null) {
      final humidite = main['humidity'] as int? ?? 60;
      final temperature = main['temp'] as double? ?? 28.0;
      
      // Alerte humidité élevée (>85%) - favorise les acariens et moisissures
      if (humidite > 85) {
        alertes.add(ModeleAlerte(
          id: 'humid_${DateTime.now().millisecondsSinceEpoch}',
          titre: 'Humidité élevée détectée',
          description: 'L\'humidité relative est de $humidite%. '
                      'Conditions favorables aux acariens et moisissures.',
          type: TypeAlerte.environnementale,
          niveauPriorite: 60,
          dateCreation: DateTime.now(),
          donneesMedicales: {
            'humidite': humidite,
            'temperature': temperature,
            'risque': 'acariens_moisissures',
          },
          recommandations: [
            'Aérez régulièrement votre logement',
            'Utilisez un déshumidificateur si possible',
            'Évitez de faire sécher du linge à l\'intérieur',
          ],
          tags: ['environnement', 'humidite', 'acariens'],
          source: 'OpenWeatherMap',
        ));
      }
      
      // Alerte température extrême (>35°C)
      if (temperature > 35) {
        alertes.add(ModeleAlerte(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          titre: 'Température élevée',
          description: 'Température de ${temperature.toStringAsFixed(1)}°C. '
                      'Risque de déshydratation et stress thermique.',
          type: TypeAlerte.environnementale,
          niveauPriorite: 65,
          dateCreation: DateTime.now(),
          donneesMedicales: {
            'temperature': temperature,
            'ressenti': main['feels_like'],
            'risque': 'stress_thermique',
          },
          recommandations: [
            'Hydratez-vous régulièrement',
            'Évitez les efforts physiques intenses',
            'Restez dans des endroits climatisés',
          ],
          tags: ['environnement', 'temperature', 'chaleur'],
          source: 'OpenWeatherMap',
        ));
      }
    }
    
    return alertes;
  }

  /// Obtient les recommandations basées sur l'AQI
  List<String> _obtenirRecommandationsAQI(int aqi) {
    if (aqi <= 50) {
      return ['La qualité de l\'air est bonne'];
    } else if (aqi <= 100) {
      return [
        'Limitez les activités prolongées à l\'extérieur',
        'Les personnes sensibles devraient réduire l\'effort physique',
      ];
    } else if (aqi <= 150) {
      return [
        'Évitez les activités extérieures prolongées',
        'Portez un masque si vous devez sortir',
        'Gardez les fenêtres fermées',
      ];
    } else {
      return [
        'Évitez toute activité extérieure',
        'Restez à l\'intérieur avec les fenêtres fermées',
        'Utilisez un purificateur d\'air',
        'Consultez un médecin si vous ressentez des symptômes',
      ];
    }
  }

  /// Obtient les dernières données environnementales
  Map<String, dynamic>? get dernieresdonneesEnvironnementales => _dernieresdonneesEnv;
  
  /// Obtient la date de dernière mise à jour
  DateTime? get derniereMiseAJourEnvironnementale => _derniereMiseAJourEnv;
  
  /// Test de connectivité
  Future<bool> testerConnectivite() async {
    if (_modeSimulation) {
      debugPrint('🧪 Test connectivité environnementale (simulation): OK');
      return true;
    }
    
    // TODO: Implémenter test réel des APIs
    return false;
  }
}