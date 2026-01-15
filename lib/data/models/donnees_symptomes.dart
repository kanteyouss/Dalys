/// Modèle de données structurées pour les symptômes
/// Utilisé pour la communication avec l'IA et l'API backend
class DonneesSymptomes {
  final DateTime horodatage;
  final List<ElementSymptome> symptomes;
  final String severiteGlobale; // "leger", "moyen", "fort"
  final String? texteBrut; // Texte original de l'utilisateur
  final double confiance; // Confiance de l'extraction NLP (0.0-1.0)

  DonneesSymptomes({
    required this.horodatage,
    required this.symptomes,
    required this.severiteGlobale,
    this.texteBrut,
    this.confiance = 1.0,
  });

  /// Crée des données de symptômes vides
  factory DonneesSymptomes.vide() {
    return DonneesSymptomes(
      horodatage: DateTime.now(),
      symptomes: [],
      severiteGlobale: 'leger',
      confiance: 0.0,
    );
  }

  /// Convertit vers JSON pour l'API
  Map<String, dynamic> versJson() {
    return {
      'horodatage': horodatage.toIso8601String(),
      'symptomes': symptomes.map((s) => s.versJson()).toList(),
      'severite_globale': severiteGlobale,
      'texte_brut': texteBrut,
      'confiance': confiance,
    };
  }

  /// Crée depuis JSON
  factory DonneesSymptomes.depuisJson(Map<String, dynamic> json) {
    return DonneesSymptomes(
      horodatage: DateTime.parse(json['horodatage'] as String),
      symptomes: (json['symptomes'] as List)
          .map((s) => ElementSymptome.depuisJson(s as Map<String, dynamic>))
          .toList(),
      severiteGlobale: json['severite_globale'] as String,
      texteBrut: json['texte_brut'] as String?,
      confiance: (json['confiance'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Obtient la liste des noms de symptômes
  List<String> get nomsSymptomes => symptomes.map((s) => s.nom).toList();

  /// Vérifie si des symptômes ont été détectés
  bool get aSymptomes => symptomes.isNotEmpty;

  /// Vérifie si la sévérité est élevée
  bool get estGrave => severiteGlobale == 'fort' || severiteGlobale == 'grave';

  /// Compte le nombre de symptômes
  int get nombreSymptomes => symptomes.length;

  @override
  String toString() {
    return 'DonneesSymptomes(symptomes: ${nomsSymptomes.join(", ")}, severite: $severiteGlobale)';
  }
}

/// Représente un symptôme individuel avec sa sévérité
class ElementSymptome {
  final String nom; // Nom du symptôme (ex: "toux", "fatigue")
  final String? severite; // Sévérité spécifique si différente de la globale
  final String? description; // Description additionnelle
  final Map<String, dynamic> metadonnees; // Métadonnées supplémentaires

  ElementSymptome({
    required this.nom,
    this.severite,
    this.description,
    Map<String, dynamic>? metadonnees,
  }) : metadonnees = metadonnees ?? {};

  /// Convertit vers JSON
  Map<String, dynamic> versJson() {
    return {
      'nom': nom,
      'severite': severite,
      'description': description,
      'metadonnees': metadonnees,
    };
  }

  /// Crée depuis JSON
  factory ElementSymptome.depuisJson(Map<String, dynamic> json) {
    return ElementSymptome(
      nom: json['nom'] as String,
      severite: json['severite'] as String?,
      description: json['description'] as String?,
      metadonnees: json['metadonnees'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'ElementSymptome(nom: $nom${severite != null ? ", severite: $severite" : ""})';
  }
}

/// Résultat de l'analyse IA des symptômes
class PredictionIA {
  final int scoreRisque; // Score de risque 0-100
  final String niveauRisque; // "faible", "moyen", "eleve"
  final List<String> recommandations; // Recommandations personnalisées
  final bool doitCreerAlerte; // Si une alerte doit être créée
  final String? messageAlerte; // Message d'alerte si nécessaire
  final Map<String, dynamic> analyse; // Analyse détaillée

  PredictionIA({
    required this.scoreRisque,
    required this.niveauRisque,
    required this.recommandations,
    this.doitCreerAlerte = false,
    this.messageAlerte,
    Map<String, dynamic>? analyse,
  }) : analyse = analyse ?? {};

  /// Convertit vers JSON
  Map<String, dynamic> versJson() {
    return {
      'score_risque': scoreRisque,
      'niveau_risque': niveauRisque,
      'recommandations': recommandations,
      'doit_creer_alerte': doitCreerAlerte,
      'message_alerte': messageAlerte,
      'analyse': analyse,
    };
  }

  /// Crée depuis JSON
  factory PredictionIA.depuisJson(Map<String, dynamic> json) {
    return PredictionIA(
      scoreRisque: json['score_risque'] as int,
      niveauRisque: json['niveau_risque'] as String,
      recommandations: List<String>.from(json['recommandations'] as List),
      doitCreerAlerte: json['doit_creer_alerte'] as bool? ?? false,
      messageAlerte: json['message_alerte'] as String?,
      analyse: json['analyse'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Obtient une couleur basée sur le niveau de risque
  String get couleurRisque {
    switch (niveauRisque) {
      case 'faible':
        return '#4CAF50'; // Vert
      case 'moyen':
        return '#FF9800'; // Orange
      case 'eleve':
        return '#F44336'; // Rouge
      default:
        return '#9E9E9E'; // Gris
    }
  }

  /// Obtient un message de risque en français
  String get messageRisque {
    switch (niveauRisque) {
      case 'faible':
        return 'Risque faible';
      case 'moyen':
        return 'Risque modéré';
      case 'eleve':
        return 'Risque élevé';
      default:
        return 'Risque inconnu';
    }
  }

  @override
  String toString() {
    return 'PredictionIA(scoreRisque: $scoreRisque, niveauRisque: $niveauRisque, recommandations: ${recommandations.length})';
  }
}
