import 'dart:async';
import 'dart:math';
import '../models/modele_alerte.dart';


/// Fournisseur de données simulées pour les alertes médicales
/// Génère des alertes de test pour valider le fonctionnement de l'application
class FournisseurAlertesTest {
  /// Instance singleton du fournisseur
  static final FournisseurAlertesTest _instance = FournisseurAlertesTest._internal();
  factory FournisseurAlertesTest() => _instance;
  FournisseurAlertesTest._internal();

  /// Générateur de nombres aléatoires
  final Random _random = Random();

  /// Timer pour la génération automatique d'alertes
  Timer? _timerGeneration;

  /// Stream controller pour diffuser les nouvelles alertes
  final StreamController<ModeleAlerte> _controllerAlertes = 
      StreamController<ModeleAlerte>.broadcast();

  /// Stream des nouvelles alertes générées
  Stream<ModeleAlerte> get streamNouvellesAlertes => _controllerAlertes.stream;

  /// Liste des alertes de test prédéfinies
  final List<Map<String, dynamic>> _alertesPredefines = [
    // Alertes IA
    {
      'type': TypeAlerte.ia,
      'titre': 'Risque d\'asthme détecté',
      'message': 'Les paramètres respiratoires indiquent un risque élevé de crise d\'asthme dans les 2 prochaines heures.',
      'severite': NiveauSeverite.eleve,
      'recommandations': [
        'Gardez votre inhalateur à portée de main',
        'Évitez les efforts physiques intenses',
        'Surveillez votre respiration de près'
      ],
      'source': 'Intelligence Artificielle',
    },
    {
      'type': TypeAlerte.ia,
      'titre': 'Amélioration prévue',
      'message': 'Vos paramètres respiratoires montrent une tendance à l\'amélioration.',
      'severite': NiveauSeverite.faible,
      'recommandations': [
        'Continuez vos bonnes habitudes',
        'Maintenez votre routine de traitement'
      ],
      'source': 'Prédiction IA',
    },

    // Alertes environnementales
    {
      'type': TypeAlerte.environnementale,
      'titre': 'Pic de pollution',
      'message': 'La qualité de l\'air est très mauvaise aujourd\'hui. Indice de pollution: 85/100.',
      'severite': NiveauSeverite.eleve,
      'recommandations': [
        'Évitez les activités extérieures',
        'Gardez les fenêtres fermées',
        'Utilisez un purificateur d\'air si possible'
      ],
      'source': 'Station météorologique',
    },
    {
      'type': TypeAlerte.environnementale,
      'titre': 'Taux de pollen élevé',
      'message': 'Concentration élevée de pollens de bouleau aujourd\'hui.',
      'severite': NiveauSeverite.modere,
      'recommandations': [
        'Prenez vos antihistaminiques',
        'Évitez les parcs et jardins',
        'Portez des lunettes de soleil'
      ],
      'source': 'Réseau pollinique',
    },

    // Alertes médicales
    {
      'type': TypeAlerte.medicale,
      'titre': 'SpO₂ en dessous du seuil',
      'message': 'Votre saturation en oxygène est de 91%, en dessous de la normale.',
      'severite': NiveauSeverite.eleve,
      'recommandations': [
        'Asseyez-vous et reposez-vous',
        'Respirez lentement et profondément',
        'Contactez votre médecin si cela persiste'
      ],
      'source': 'Capteur SpO₂',
    },
    {
      'type': TypeAlerte.medicale,
      'titre': 'Fréquence respiratoire élevée',
      'message': 'Votre rythme respiratoire est de 28 bpm, au-dessus de la normale.',
      'severite': NiveauSeverite.modere,
      'recommandations': [
        'Ralentissez vos activités',
        'Pratiquez des exercices de respiration',
        'Surveillez votre état'
      ],
      'source': 'Capteur respiratoire',
    },

    // Alertes manuelles/rappels
    {
      'type': TypeAlerte.manuelle,
      'titre': 'Rappel: Prise de médicament',
      'message': 'Il est temps de prendre votre bronchodilatateur.',
      'severite': NiveauSeverite.modere,
      'recommandations': [
        'Prenez 2 bouffées d\'inhalateur',
        'Attendez 1 minute entre chaque bouffée',
        'Rincez-vous la bouche après'
      ],
      'source': 'Rappel programmé',
    },
    {
      'type': TypeAlerte.manuelle,
      'titre': 'Rendez-vous médical',
      'message': 'Rappel: consultation pneumologue demain à 14h30.',
      'severite': NiveauSeverite.faible,
      'recommandations': [
        'Préparez vos questions',
        'Apportez vos derniers résultats',
        'Arrivez 15 minutes en avance'
      ],
      'source': 'Agenda médical',
    }
  ];

  /// Démarre la génération automatique d'alertes de test
  /// Génère une nouvelle alerte toutes les [intervalle] secondes
  void demarrerGenerationAutomatique({int intervalleSecondes = 45}) {
    arreterGenerationAutomatique();
    
    _timerGeneration = Timer.periodic(
      Duration(seconds: intervalleSecondes),
      (_) => genererAlerteAleatoire(),
    );
    
    print('🔄 Génération automatique d\'alertes démarrée (intervalle: ${intervalleSecondes}s)');
  }

  /// Arrête la génération automatique d'alertes
  void arreterGenerationAutomatique() {
    _timerGeneration?.cancel();
    _timerGeneration = null;
    print('⏹️ Génération automatique d\'alertes arrêtée');
  }

  /// Génère une alerte aléatoire et l'émet via le stream
  ModeleAlerte genererAlerteAleatoire() {
    final donneesAlerte = _alertesPredefines[_random.nextInt(_alertesPredefines.length)];
    
    final alerte = ModeleAlerte(
      id: 'alerte_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      type: donneesAlerte['type'],
      titre: donneesAlerte['titre'],
      description: _ajouterVariationMessage(donneesAlerte['message']),
      niveauPriorite: (donneesAlerte['severite'] as NiveauSeverite).priorite,
      dateCreation: DateTime.now(),
      recommandations: List<String>.from(donneesAlerte['recommandations']),
      statut: StatutAlerte.nouvelle,
      source: donneesAlerte['source'],
    );

    // Émettre l'alerte via le stream
    _controllerAlertes.add(alerte);
    
    print('📱 Nouvelle alerte générée: ${alerte.titre}');
    return alerte;
  }

  /// Génère une alerte critique de test
  ModeleAlerte genererAlerteCritique() {
    final alertesCritiques = [
      {
        'titre': '🚨 URGENCE RESPIRATOIRE',
        'message': 'SpO₂ dangereusement bas (87%). Action immédiate requise.',
        'recommandations': [
          'APPELEZ IMMÉDIATEMENT LES SECOURS (15)',
          'Utilisez votre inhalateur d\'urgence',
          'Asseyez-vous en position haute',
          'Restez calme et respirez lentement'
        ]
      },
      {
        'titre': '⚠️ CRISE D\'ASTHME SÉVÈRE',
        'message': 'Détection de paramètres critiques. Risque de crise majeure.',
        'recommandations': [
          'Utilisez immédiatement votre bronchodilatateur',
          'Appelez votre médecin ou le 15',
          'Évitez tout effort physique',
          'Préparez-vous à vous rendre aux urgences'
        ]
      }
    ];

    final donnees = alertesCritiques[_random.nextInt(alertesCritiques.length)];
    
    final alerte = ModeleAlerte(
      id: 'critique_${DateTime.now().millisecondsSinceEpoch}',
      type: TypeAlerte.medicale,
      titre: donnees['titre'] as String,
      description: donnees['message'] as String,
      niveauPriorite: NiveauSeverite.critique.priorite,
      dateCreation: DateTime.now(),
      recommandations: List<String>.from(donnees['recommandations'] as List),
      statut: StatutAlerte.nouvelle,
      source: 'Système de surveillance',
    );

    _controllerAlertes.add(alerte);
    print('🚨 ALERTE CRITIQUE générée: ${alerte.titre}');
    return alerte;
  }

  /// Génère un lot d'alertes pour l'historique de test
  List<ModeleAlerte> genererHistoriqueTest({int nombreAlertes = 15}) {
    final historique = <ModeleAlerte>[];
    
    for (int i = 0; i < nombreAlertes; i++) {
      final donneesAlerte = _alertesPredefines[_random.nextInt(_alertesPredefines.length)];
      
      // Générer des dates dans les derniers jours
      final horodatage = DateTime.now().subtract(Duration(
        hours: _random.nextInt(72), // Dernières 72 heures
        minutes: _random.nextInt(60),
      ));
      
      final alerte = ModeleAlerte(
        id: 'historique_${horodatage.millisecondsSinceEpoch}_$i',
        type: donneesAlerte['type'],
        titre: donneesAlerte['titre'],
        description: _ajouterVariationMessage(donneesAlerte['message']),
        niveauPriorite: (donneesAlerte["severite"] as NiveauSeverite).priorite,
        dateCreation: horodatage,
        recommandations: List<String>.from(donneesAlerte['recommandations']),
        statut: _random.nextBool() ? StatutAlerte.lue : StatutAlerte.nouvelle, // Certaines lues, d'autres non
        source: donneesAlerte['source'],
      );
      
      historique.add(alerte);
    }
    
    // Trier par date (plus récentes en premier)
    historique.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    
    print('📚 Historique de test généré: $nombreAlertes alertes');
    return historique;
  }

  /// Génère une alerte personnalisée avec des paramètres spécifiques
  ModeleAlerte genererAlertePersonnalisee({
    required TypeAlerte type,
    required String titre,
    required String description,
    required NiveauSeverite niveauPriorite,
    List<String> recommandations = const [],
    String source = 'Test personnalisé',
    bool estLu = false,
  }) {
    final alerte = ModeleAlerte(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      titre: titre,
      description: description,
      niveauPriorite: niveauPriorite.priorite,
      dateCreation: DateTime.now(),
      recommandations: recommandations,
      statut: estLu ? StatutAlerte.lue : StatutAlerte.nouvelle,
      source: source,
    );

    _controllerAlertes.add(alerte);
    print('🎯 Alerte personnalisée générée: $titre');
    return alerte;
  }

  /// Génère des alertes selon un scénario médical spécifique
  List<ModeleAlerte> genererScenarioMedical(String typeScenario) {
    final alertes = <ModeleAlerte>[];
    
    switch (typeScenario.toLowerCase()) {
      case 'crise_asthme':
        // Séquence d'une crise d'asthme
        alertes.addAll([
          _creerAlerte('Signes précurseurs détectés', NiveauSeverite.faible, TypeAlerte.ia),
          _creerAlerte('Dégradation des paramètres', NiveauSeverite.modere, TypeAlerte.medicale),
          _creerAlerte('Risque de crise élevé', NiveauSeverite.eleve, TypeAlerte.ia),
          _creerAlerte('CRISE D\'ASTHME EN COURS', NiveauSeverite.critique, TypeAlerte.medicale),
        ]);
        break;
        
      case 'pollution':
        // Pic de pollution et ses effets
        alertes.addAll([
          _creerAlerte('Qualité d\'air dégradée', NiveauSeverite.faible, TypeAlerte.environnementale),
          _creerAlerte('Pic de pollution confirmé', NiveauSeverite.modere, TypeAlerte.environnementale),
          _creerAlerte('Impact sur les voies respiratoires', NiveauSeverite.eleve, TypeAlerte.medicale),
        ]);
        break;
        
      case 'surveillance':
        // Suivi médical normal
        alertes.addAll([
          _creerAlerte('Paramètres stables', NiveauSeverite.faible, TypeAlerte.medicale),
          _creerAlerte('Légère amélioration', NiveauSeverite.faible, TypeAlerte.ia),
          _creerAlerte('Rappel: prise de médicament', NiveauSeverite.modere, TypeAlerte.manuelle),
        ]);
        break;
    }
    
    alertes.forEach(_controllerAlertes.add);
    print('🎭 Scénario "$typeScenario" généré: ${alertes.length} alertes');
    return alertes;
  }

  /// Méthodes utilitaires privées

  /// Ajoute des variations aléatoires aux messages pour plus de réalisme
  String _ajouterVariationMessage(String messageBase) {
    final variations = [
      messageBase, // Message original
      '$messageBase Surveillez votre état.',
      '$messageBase Prenez les précautions nécessaires.',
      messageBase.replaceAll('.', ' à ${_obtenirHeureActuelle()}.'),
    ];
    
    return variations[_random.nextInt(variations.length)];
  }

  /// Crée une alerte rapide pour les scénarios
  ModeleAlerte _creerAlerte(String titre, NiveauSeverite severite, TypeAlerte type) {
    return ModeleAlerte(
      id: 'scenario_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      titre: titre,
      description: 'Message de test pour le scénario - $titre',
      niveauPriorite: severite.priorite,
      dateCreation: DateTime.now(),
      recommandations: ['Recommandation de test'],
      statut: StatutAlerte.nouvelle,
      source: 'Scénario de test',
    );
  }

  /// Obtient l'heure actuelle formatée
  String _obtenirHeureActuelle() {
    final maintenant = DateTime.now();
    return '${maintenant.hour.toString().padLeft(2, '0')}:${maintenant.minute.toString().padLeft(2, '0')}';
  }

  /// Nettoie les ressources
  void dispose() {
    arreterGenerationAutomatique();
    _controllerAlertes.close();
  }
}

/// Extension utilitaire pour le fournisseur de test
extension FournisseurAlertesTestUtilitaires on FournisseurAlertesTest {
  /// Génère rapidement des alertes pour les tests d'interface
  void genererAlertesPourTestsUI() {
    genererAlertePersonnalisee(
      type: TypeAlerte.ia,
      titre: 'Test UI - IA',
      description: 'Message de test pour vérifier l\'affichage des alertes IA.',
      niveauPriorite: NiveauSeverite.modere,
    );
    
    genererAlertePersonnalisee(
      type: TypeAlerte.environnementale,
      titre: 'Test UI - Environnement',
      description: 'Message de test pour vérifier l\'affichage des alertes environnementales.',
      niveauPriorite: NiveauSeverite.eleve,
    );
    
    genererAlerteCritique();
  }
}