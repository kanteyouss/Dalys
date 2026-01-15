import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;


/// Service de géolocalisation pour déterminer le fuseau horaire approprié
/// Adapté spécifiquement pour la Côte d'Ivoire avec fallback intelligent
class ServiceGeolocalisation {
  /// Instance singleton du service
  static final ServiceGeolocalisation _instance = ServiceGeolocalisation._internal();
  factory ServiceGeolocalisation() => _instance;
  ServiceGeolocalisation._internal();


  
  /// Position actuelle mise en cache
  Position? _positionActuelle;
  
  /// Fuseau horaire détecté mis en cache
  tz.Location? _fuseauHoraireCache;
  
  /// Dernière mise à jour de la position
  DateTime? _derniereMiseAJour;
  
  /// Durée de validité du cache (2 heures)
  static const Duration _dureeValiditeCache = Duration(hours: 2);

  /// Initialise le service de géolocalisation
  /// Configure les permissions et initialise les fuseaux horaires
  Future<bool> initialiser() async {
    try {
      // Initialiser la base de données des fuseaux horaires
      await _initialiserFuseauxHoraires();
      
      // Vérifier les permissions
      final permissionsAccordees = await _verifierPermissionsLocalisation();
      if (!permissionsAccordees) {
        debugPrint('⚠️ Permissions de géolocalisation non accordées - utilisation du fuseau par défaut');
        return false;
      }
      
      // Tenter d'obtenir la position actuelle
      await _obtenirPositionActuelle();
      
      debugPrint('✅ Service de géolocalisation initialisé');
      return true;
      
    } catch (erreur) {
      debugPrint('❌ Erreur initialisation géolocalisation: $erreur');
      return false;
    }
  }

  /// Obtient le fuseau horaire le plus approprié
  /// Priorité: Position GPS > Paramètres système > Défaut Côte d'Ivoire
  Future<tz.Location> obtenirFuseauHoraireOptimal() async {
    // Vérifier si le cache est encore valide
    if (_fuseauHoraireCache != null && 
        _derniereMiseAJour != null &&
        DateTime.now().difference(_derniereMiseAJour!) < _dureeValiditeCache) {
      debugPrint('📍 Fuseau horaire depuis le cache: ${_fuseauHoraireCache!.name}');
      return _fuseauHoraireCache!;
    }

    try {
      // Méthode 1: Géolocalisation GPS
      final fuseauGPS = await _obtenirFuseauParGPS();
      if (fuseauGPS != null) {
        _mettreEnCache(fuseauGPS);
        debugPrint('🌍 Fuseau horaire détecté par GPS: ${fuseauGPS.name}');
        return fuseauGPS;
      }

      // Méthode 2: Paramètres système de l'appareil
      final fuseauSysteme = await _obtenirFuseauParSysteme();
      if (fuseauSysteme != null) {
        _mettreEnCache(fuseauSysteme);
        debugPrint('📱 Fuseau horaire détecté par système: ${fuseauSysteme.name}');
        return fuseauSysteme;
      }

      // Méthode 3: Détection par région (Afrique de l'Ouest)
      final fuseauRegion = _obtenirFuseauParRegion();
      _mettreEnCache(fuseauRegion);
      debugPrint('🌍 Fuseau horaire par région: ${fuseauRegion.name}');
      return fuseauRegion;

    } catch (erreur) {
      debugPrint('❌ Erreur détection fuseau horaire: $erreur');
      
      // Fallback: Côte d'Ivoire par défaut
      final fuseauDefaut = _obtenirFuseauParDefaut();
      _mettreEnCache(fuseauDefaut);
      debugPrint('🇨🇮 Fuseau horaire par défaut (Abidjan): ${fuseauDefaut.name}');
      return fuseauDefaut;
    }
  }

  /// Demande explicitement la permission de géolocalisation à l'utilisateur
  /// Affiche un dialog explicatif pour améliorer l'UX
  Future<bool> demanderPermissionAvecDialog(BuildContext context) async {
    // Vérifier d'abord si les permissions sont déjà accordées
    final statutActuel = await Geolocator.checkPermission();
    if (statutActuel == LocationPermission.always || 
        statutActuel == LocationPermission.whileInUse) {
      return true;
    }

    // Afficher le dialog explicatif
    final accord = await _afficherDialogPermission(context);
    if (!accord) return false;

    // Demander les permissions
    return await _demanderPermissionsLocalisation();
  }

  /// Obtient des informations détaillées sur la localisation actuelle
  Future<Map<String, dynamic>> obtenirInformationsLocalisation() async {
    final informations = <String, dynamic>{
      'position_disponible': _positionActuelle != null,
      'derniere_mise_a_jour': _derniereMiseAJour?.toIso8601String(),
      'fuseau_cache': _fuseauHoraireCache?.name,
      'precision_gps': null,
      'coordonnees': null,
    };

    if (_positionActuelle != null) {
      informations.addAll({
        'precision_gps': _positionActuelle!.accuracy,
        'coordonnees': {
          'latitude': _positionActuelle!.latitude,
          'longitude': _positionActuelle!.longitude,
        },
        'altitude': _positionActuelle!.altitude,
        'vitesse': _positionActuelle!.speed,
        'cap': _positionActuelle!.heading,
        'horodatage_gps': _positionActuelle!.timestamp.toIso8601String(),
      });
    }

    return informations;
  }

  /// Actualise la position et le fuseau horaire
  Future<void> actualiserLocalisation() async {
    _derniereMiseAJour = null; // Forcer la mise à jour
    _fuseauHoraireCache = null;
    await _obtenirPositionActuelle();
    await obtenirFuseauHoraireOptimal();
  }

  /// Méthodes privées pour la détection du fuseau horaire

  /// Initialise la base de données des fuseaux horaires
  Future<void> _initialiserFuseauxHoraires() async {
    try {
      // Charger les données de fuseaux horaires si nécessaire
      if (tz.timeZoneDatabase.locations.isEmpty) {
        // La base de données sera chargée automatiquement au premier accès
        debugPrint('📅 Base de données des fuseaux horaires initialisée');
      }
    } catch (erreur) {
      debugPrint('⚠️ Erreur initialisation fuseaux horaires: $erreur');
    }
  }

  /// Obtient le fuseau horaire basé sur la position GPS
  Future<tz.Location?> _obtenirFuseauParGPS() async {
    if (_positionActuelle == null) {
      await _obtenirPositionActuelle();
    }

    if (_positionActuelle == null) return null;

    final latitude = _positionActuelle!.latitude;
    final longitude = _positionActuelle!.longitude;

    // Détection spécifique pour la Côte d'Ivoire et l'Afrique de l'Ouest
    if (_estEnCoteIvoire(latitude, longitude)) {
      return tz.getLocation('Africa/Abidjan');
    }

    // Autres pays d'Afrique de l'Ouest
    if (_estEnAfriqueOuest(latitude, longitude)) {
      return _determinerFuseauAfriqueOuest(latitude, longitude);
    }

    // Détection globale approximative
    return _determinerFuseauParCoordonnees(latitude, longitude);
  }

  /// Obtient le fuseau horaire à partir des paramètres système
  Future<tz.Location?> _obtenirFuseauParSysteme() async {
    try {
      // Obtenir le fuseau horaire du système
      final fuseauSysteme = DateTime.now().timeZoneName;
      
      // Tenter de mapper vers un fuseau tz valide
      if (fuseauSysteme.contains('GMT') || fuseauSysteme.contains('UTC')) {
        // Si c'est GMT/UTC, utiliser Abidjan (même fuseau que GMT)
        return tz.getLocation('Africa/Abidjan');
      }

      // Essayer de trouver le fuseau correspondant
      try {
        return tz.getLocation(fuseauSysteme);
      } catch (_) {
        // Si le fuseau système n'est pas reconnu, essayer des variantes
        return _essayerVariantesFuseaux(fuseauSysteme);
      }

    } catch (erreur) {
      debugPrint('⚠️ Impossible d\'obtenir le fuseau système: $erreur');
      return null;
    }
  }

  /// Obtient le fuseau horaire par région (défaut intelligent)
  tz.Location _obtenirFuseauParRegion() {
    // Pour l'Afrique de l'Ouest, Abidjan est le référent principal
    return tz.getLocation('Africa/Abidjan');
  }

  /// Obtient le fuseau horaire par défaut (Côte d'Ivoire)
  tz.Location _obtenirFuseauParDefaut() {
    return tz.getLocation('Africa/Abidjan');
  }

  /// Vérifie et demande les permissions de géolocalisation
  Future<bool> _verifierPermissionsLocalisation() async {
    final statutActuel = await Geolocator.checkPermission();
    
    switch (statutActuel) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return true;
      case LocationPermission.denied:
        return await _demanderPermissionsLocalisation();
      case LocationPermission.deniedForever:
        debugPrint('❌ Permissions géolocalisation refusées définitivement');
        return false;
      case LocationPermission.unableToDetermine:
        debugPrint('⚠️ Impossible de déterminer les permissions');
        return false;
    }
  }

  /// Demande les permissions de géolocalisation
  Future<bool> _demanderPermissionsLocalisation() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Obtient la position GPS actuelle
  Future<void> _obtenirPositionActuelle() async {
    try {
      final serviceActive = await Geolocator.isLocationServiceEnabled();
      if (!serviceActive) {
        debugPrint('❌ Service de géolocalisation désactivé');
        return;
      }

      _positionActuelle = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _derniereMiseAJour = DateTime.now();
      debugPrint('📍 Position obtenue: ${_positionActuelle!.latitude}, ${_positionActuelle!.longitude}');

    } catch (erreur) {
      debugPrint('❌ Erreur obtention position: $erreur');
      _positionActuelle = null;
    }
  }

  /// Vérifie si les coordonnées sont en Côte d'Ivoire
  bool _estEnCoteIvoire(double latitude, double longitude) {
    // Limites approximatives de la Côte d'Ivoire
    // Latitude: 4.2° N à 10.8° N
    // Longitude: 8.6° W à 2.5° W
    return latitude >= 4.2 && latitude <= 10.8 &&
           longitude >= -8.6 && longitude <= -2.5;
  }

  /// Vérifie si les coordonnées sont en Afrique de l'Ouest
  bool _estEnAfriqueOuest(double latitude, double longitude) {
    // Zone élargie d'Afrique de l'Ouest
    return latitude >= -5.0 && latitude <= 25.0 &&
           longitude >= -20.0 && longitude <= 15.0;
  }

  /// Détermine le fuseau horaire pour l'Afrique de l'Ouest
  tz.Location _determinerFuseauAfriqueOuest(double latitude, double longitude) {
    // Mapping approximatif des pays d'Afrique de l'Ouest
    if (longitude >= -8.6 && longitude <= -2.5) {
      // Zone GMT (Côte d'Ivoire, Ghana, Mali, etc.)
      return tz.getLocation('Africa/Abidjan');
    } else if (longitude >= -2.5 && longitude <= 4.0) {
      // Zone GMT+1 (Nigeria, Cameroun, etc.)
      return tz.getLocation('Africa/Lagos');
    } else {
      // Par défaut, Abidjan
      return tz.getLocation('Africa/Abidjan');
    }
  }

  /// Détermine le fuseau horaire global par coordonnées (approximatif)
  tz.Location _determinerFuseauParCoordonnees(double latitude, double longitude) {
    // Calcul approximatif basé sur la longitude
    // Chaque 15° de longitude ≈ 1 heure de décalage
    final decalageHeures = (longitude / 15.0).round();
    
    try {
      // Essayer de trouver un fuseau correspondant
      if (decalageHeures == 0) {
        return tz.getLocation('Africa/Abidjan'); // GMT
      } else if (decalageHeures == 1) {
        return tz.getLocation('Africa/Lagos'); // GMT+1
      } else {
        // Fallback vers Abidjan
        return tz.getLocation('Africa/Abidjan');
      }
    } catch (_) {
      return tz.getLocation('Africa/Abidjan');
    }
  }

  /// Essaie différentes variantes de noms de fuseaux
  tz.Location? _essayerVariantesFuseaux(String fuseauSysteme) {
    final variantes = [
      'Africa/Abidjan',
      'UTC',
      'GMT',
      'Africa/Lagos',
      'Europe/London',
    ];

    for (final variante in variantes) {
      try {
        return tz.getLocation(variante);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  /// Met en cache le fuseau horaire détecté
  void _mettreEnCache(tz.Location fuseau) {
    _fuseauHoraireCache = fuseau;
    _derniereMiseAJour = DateTime.now();
  }

  /// Affiche un dialog pour expliquer pourquoi la géolocalisation est nécessaire
  Future<bool> _afficherDialogPermission(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Géolocalisation'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour améliorer votre expérience avec les notifications médicales, '
              'nous aimerions détecter votre fuseau horaire automatiquement.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              '🌍 Cela nous permet de :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Programmer les rappels à la bonne heure'),
            Text('• Adapter les alertes à votre localisation'),
            Text('• Optimiser les notifications médicales'),
            SizedBox(height: 12),
            Text(
              '🔒 Vos données de localisation restent privées et ne sont pas partagées.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Nettoie les ressources
  void dispose() {
    _positionActuelle = null;
    _fuseauHoraireCache = null;
    _derniereMiseAJour = null;
  }
}

/// Extension utilitaire pour faciliter l'usage
extension ServiceGeolocalisationUtilitaires on ServiceGeolocalisation {
  /// Obtient une description textuelle de la localisation actuelle
  Future<String> obtenirDescriptionLocalisation() async {
    final infos = await obtenirInformationsLocalisation();
    
    if (infos['position_disponible'] == true) {
      final coords = infos['coordonnees'];
      return 'Position: ${coords['latitude'].toStringAsFixed(2)}°, '
             '${coords['longitude'].toStringAsFixed(2)}° '
             '(±${infos['precision_gps']?.toStringAsFixed(0)}m)';
    } else {
      return 'Position non disponible - utilisation du fuseau par défaut';
    }
  }
  
  /// Vérifie si l'utilisateur est probablement en Côte d'Ivoire
  Future<bool> estProbablementEnCoteIvoire() async {
    if (_positionActuelle == null) return true; // Présumé par défaut
    
    return _estEnCoteIvoire(
      _positionActuelle!.latitude, 
      _positionActuelle!.longitude,
    );
  }
}