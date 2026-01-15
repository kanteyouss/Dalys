import 'package:flutter/material.dart';

/// Modèle de données unifié pour les alertes médicales du système E-Santé 4.0
/// Fusion des deux versions précédentes avec toutes les fonctionnalités

/// Énumération des types d'alertes disponibles
enum TypeAlerte {
  // Types prioritaires/urgents
  critique('critique', 'Critique', Icons.error, Colors.red),
  haute('haute', 'Priorité Haute', Icons.warning, Colors.orange),
  
  // Types médicaux spécifiques
  medicament('medicament', 'Médicament', Icons.medication, Colors.teal),
  rendezvous('rendezvous', 'Rendez-vous', Icons.event, Colors.indigo),
  
  // Types généraux
  moyenne('moyenne', 'Priorité Moyenne', Icons.info, Colors.blue),
  basse('basse', 'Priorité Basse', Icons.notifications, Colors.green),
  rappel('rappel', 'Rappel', Icons.access_time, Colors.purple),
  systeme('systeme', 'Système', Icons.settings, Colors.grey),
  
  // Types métier (compatibilité ancien modèle)
  ia('ia', 'Intelligence Artificielle', Icons.psychology, Colors.deepPurple),
  environnementale('environnementale', 'Environnementale', Icons.eco, Colors.lightGreen),
  medicale('medicale', 'Médicale', Icons.local_hospital, Colors.red),
  manuelle('manuelle', 'Manuelle', Icons.person, Colors.blueGrey);

  const TypeAlerte(this.valeur, this.libelle, this.icone, this.couleur);
  
  /// Valeur technique du type
  final String valeur;
  
  /// Libellé affiché à l'utilisateur
  final String libelle;
  
  /// Icône représentative
  final IconData icone;
  
  /// Couleur associée
  final Color couleur;

  /// Convertit une chaîne en TypeAlerte
  static TypeAlerte depuisChaine(String valeur) {
    return TypeAlerte.values.firstWhere(
      (type) => type.valeur == valeur || type.name == valeur,
      orElse: () => TypeAlerte.moyenne,
    );
  }

  /// Retourne l'emoji associé au type (compatibilité ancien modèle)
  String get emoji {
    switch (this) {
      case TypeAlerte.ia:
        return '🤖';
      case TypeAlerte.environnementale:
        return '🌍';
      case TypeAlerte.medicale:
      case TypeAlerte.medicament:
        return '🏥';
      case TypeAlerte.manuelle:
        return '👤';
      case TypeAlerte.critique:
        return '🚨';
      case TypeAlerte.rendezvous:
        return '📅';
      default:
        return '🔔';
    }
  }
}

/// Énumération des statuts d'alerte
enum StatutAlerte {
  nouvelle('nouvelle', 'Nouvelle', Icons.fiber_new, Colors.red),
  lue('lue', 'Lue', Icons.mark_email_read, Colors.blue),
  enCours('en_cours', 'En cours', Icons.hourglass_bottom, Colors.orange),
  resolue('resolue', 'Résolue', Icons.check_circle, Colors.green),
  ignoree('ignoree', 'Ignorée', Icons.visibility_off, Colors.grey),
  reportee('reportee', 'Reportée', Icons.schedule, Colors.purple);

  const StatutAlerte(this.valeur, this.libelle, this.icone, this.couleur);
  
  final String valeur;
  final String libelle;
  final IconData icone;
  final Color couleur;

  static StatutAlerte depuisChaine(String valeur) {
    return StatutAlerte.values.firstWhere(
      (statut) => statut.valeur == valeur || statut.name == valeur,
      orElse: () => StatutAlerte.nouvelle,
    );
  }
}

/// Énumération des niveaux de sévérité (compatibilité ancien modèle)
enum NiveauSeverite {
  faible('faible', 'Faible', Colors.green, 25),
  modere('modere', 'Modéré', Colors.orange, 50),
  eleve('eleve', 'Élevé', Colors.red, 75),
  critique('critique', 'Critique', Colors.purple, 100);

  const NiveauSeverite(this.valeur, this.libelle, this.couleur, this.priorite);
  
  final String valeur;
  final String libelle;
  final Color couleur;
  final int priorite;

  static NiveauSeverite depuisChaine(String valeur) {
    return NiveauSeverite.values.firstWhere(
      (severite) => severite.valeur == valeur || severite.name == valeur,
      orElse: () => NiveauSeverite.faible,
    );
  }
}

/// Modèle principal unifié des alertes médicales
class ModeleAlerte {
  /// Identifiant unique de l'alerte
  final String id;
  
  /// Titre de l'alerte
  final String titre;
  
  /// Description détaillée (nouveau modèle) / Message (ancien modèle)
  final String description;
  
  /// Type d'alerte
  final TypeAlerte type;
  
  /// Statut actuel
  StatutAlerte statut;
  
  /// Date de création (nouveau) / Horodatage (ancien)
  final DateTime dateCreation;
  
  /// Date d'échéance ou de programmation
  final DateTime? dateEcheance;
  
  /// Date de dernière modification
  DateTime dateModification;
  
  /// Tags pour la catégorisation
  final List<String> tags;
  
  /// Données supplémentaires (JSON-like)
  final Map<String, dynamic> metadonnees;
  
  /// Actions disponibles pour cette alerte
  final Map<String, String> actions;
  
  /// Niveau de priorité (0-100, 100 = le plus urgent)
  final int niveauPriorite;
  
  /// Identifiant de l'utilisateur concerné
  final String? idUtilisateur;
  
  /// Données médicales associées / Données métier (fusion)
  final Map<String, dynamic>? donneesMedicales;
  
  /// Indicateur si l'alerte peut se répéter
  final bool estRecurrente;
  
  /// Configuration de récurrence si applicable
  final Map<String, dynamic>? configurationRecurrence;
  
  /// Recommandations d'actions à prendre (ancien modèle)
  final List<String> recommandations;
  
  /// Source de données (ancien modèle)
  final String source;
  
  /// Date d'expiration (ancien modèle)
  final DateTime? dateExpiration;

  /// Constructeur principal unifié
  ModeleAlerte({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    this.statut = StatutAlerte.nouvelle,
    required this.dateCreation,
    this.dateEcheance,
    DateTime? dateModification,
    this.tags = const [],
    this.metadonnees = const {},
    this.actions = const {},
    this.niveauPriorite = 50,
    this.idUtilisateur,
    this.donneesMedicales,
    this.estRecurrente = false,
    this.configurationRecurrence,
    this.recommandations = const [],
    this.source = 'E-Santé 4.0',
    this.dateExpiration,
  }) : dateModification = dateModification ?? dateCreation;

  /// Constructeur de compatibilité avec l'ancien modèle
  ModeleAlerte.depuisAncien({
    required String id,
    required TypeAlerte type,
    required String titre,
    required String message,
    required NiveauSeverite severite,
    required DateTime horodatage,
    required List<String> recommandations,
    required String source,
    bool estLu = false,
    Map<String, dynamic>? donneesMetier,
    DateTime? dateExpiration,
    int priorite = 5,
  }) : this(
    id: id,
    titre: titre,
    description: message,
    type: type,
    statut: estLu ? StatutAlerte.lue : StatutAlerte.nouvelle,
    dateCreation: horodatage,
    dateEcheance: dateExpiration,
    niveauPriorite: severite.priorite,
    donneesMedicales: donneesMetier,
    recommandations: recommandations,
    source: source,
    dateExpiration: dateExpiration,
  );

  /// Constructeur pour alerte critique avec paramètres simplifiés
  ModeleAlerte.critique({
    required String id,
    required String titre,
    required String description,
    DateTime? dateEcheance,
    Map<String, dynamic>? donneesMedicales,
    List<String> tags = const [],
  }) : this(
    id: id,
    titre: titre,
    description: description,
    type: TypeAlerte.critique,
    statut: StatutAlerte.nouvelle,
    dateCreation: DateTime.now(),
    dateEcheance: dateEcheance,
    niveauPriorite: 100,
    tags: tags,
    donneesMedicales: donneesMedicales,
    actions: {
      'consulter': 'Consulter immédiatement',
      'reporter': 'Reporter (non recommandé)',
      'ignorer': 'Marquer comme vue',
    },
  );

  /// Constructeur pour rappel de médicament
  ModeleAlerte.rappelMedicament({
    required String id,
    required String nomMedicament,
    required String posologie,
    required DateTime heureRappel,
    String? instructions,
  }) : this(
    id: id,
    titre: 'Rappel : $nomMedicament',
    description: 'Il est temps de prendre votre médicament.\n'
                'Posologie : $posologie'
                '${instructions != null ? '\nInstructions : $instructions' : ''}',
    type: TypeAlerte.medicament,
    dateCreation: DateTime.now(),
    dateEcheance: heureRappel,
    niveauPriorite: 75,
    estRecurrente: true,
    tags: ['medicament', 'rappel'],
    donneesMedicales: {
      'nom_medicament': nomMedicament,
      'posologie': posologie,
      'instructions': instructions,
    },
    actions: {
      'pris': 'Marquer comme pris',
      'reporter': 'Reporter de 15 min',
      'ignorer': 'Ignorer ce rappel',
    },
  );

  /// Constructeur pour rappel de rendez-vous
  ModeleAlerte.rappelRendezVous({
    required String id,
    required String nomMedecin,
    required String specialite,
    required DateTime dateRendezVous,
    String? adresse,
    String? telephone,
  }) : this(
    id: id,
    titre: 'Rendez-vous : $nomMedecin',
    description: 'Rappel de votre rendez-vous avec $nomMedecin ($specialite)\n'
                '${adresse != null ? 'Adresse : $adresse\n' : ''}'
                '${telephone != null ? 'Téléphone : $telephone' : ''}',
    type: TypeAlerte.rendezvous,
    dateCreation: DateTime.now(),
    dateEcheance: dateRendezVous.subtract(const Duration(hours: 2)), // 2h avant
    niveauPriorite: 85,
    tags: ['rendez-vous', 'medecin'],
    donneesMedicales: {
      'nom_medecin': nomMedecin,
      'specialite': specialite,
      'date_rendez_vous': dateRendezVous.toIso8601String(),
      'adresse': adresse,
      'telephone': telephone,
    },
    actions: {
      'confirmer': 'Confirmer présence',
      'reporter': 'Reporter le rendez-vous',
      'annuler': 'Annuler le rendez-vous',
    },
  );

  /// Méthodes de compatibilité avec l'ancien modèle

  /// Alias pour description (compatibilité ancien modèle)
  String get message => description;
  
  /// Alias pour dateCreation (compatibilité ancien modèle)
  DateTime get horodatage => dateCreation;
  
  /// Indique si l'utilisateur a lu l'alerte (compatibilité ancien modèle)
  bool get estLu => statut != StatutAlerte.nouvelle;
  
  /// Données métier (alias pour donneesMedicales)
  Map<String, dynamic>? get donneesMetier => donneesMedicales;
  
  /// Priorité pour tri (ancien modèle utilisait 1-10, nouveau 0-100)
  int get priorite => (niveauPriorite / 10).round().clamp(1, 10);
  
  /// Calcule le niveau de sévérité basé sur la priorité
  NiveauSeverite get severite {
    if (niveauPriorite >= 90) return NiveauSeverite.critique;
    if (niveauPriorite >= 70) return NiveauSeverite.eleve;
    if (niveauPriorite >= 40) return NiveauSeverite.modere;
    return NiveauSeverite.faible;
  }

  /// Crée une copie de l'alerte avec des modifications (nouveau modèle)
  ModeleAlerte copierAvec({
    String? titre,
    String? description,
    TypeAlerte? type,
    StatutAlerte? statut,
    DateTime? dateEcheance,
    List<String>? tags,
    Map<String, dynamic>? metadonnees,
    Map<String, String>? actions,
    int? niveauPriorite,
    Map<String, dynamic>? donneesMedicales,
    bool? estRecurrente,
  }) {
    return ModeleAlerte(
      id: id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      dateCreation: dateCreation,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      dateModification: DateTime.now(),
      tags: tags ?? this.tags,
      metadonnees: metadonnees ?? this.metadonnees,
      actions: actions ?? this.actions,
      niveauPriorite: niveauPriorite ?? this.niveauPriorite,
      idUtilisateur: idUtilisateur,
      donneesMedicales: donneesMedicales ?? this.donneesMedicales,
      estRecurrente: estRecurrente ?? this.estRecurrente,
      configurationRecurrence: configurationRecurrence,
      recommandations: recommandations,
      source: source,
      dateExpiration: dateExpiration,
    );
  }

  /// Crée une copie avec des modifications (compatibilité ancien modèle)
  ModeleAlerte copiAvec({
    String? id,
    TypeAlerte? type,
    String? titre,
    String? message,
    NiveauSeverite? severite,
    DateTime? horodatage,
    List<String>? recommandations,
    bool? estLu,
    String? source,
    Map<String, dynamic>? donneesMetier,
    DateTime? dateExpiration,
    int? priorite,
  }) {
    return ModeleAlerte(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: message ?? description,
      type: type ?? this.type,
      statut: estLu != null 
          ? (estLu ? StatutAlerte.lue : StatutAlerte.nouvelle)
          : statut,
      dateCreation: horodatage ?? dateCreation,
      dateEcheance: dateExpiration ?? dateEcheance,
      dateModification: DateTime.now(),
      niveauPriorite: severite?.priorite ?? (priorite != null 
          ? (priorite * 10).clamp(0, 100) 
          : niveauPriorite),
      donneesMedicales: donneesMetier ?? donneesMedicales,
      recommandations: recommandations ?? this.recommandations,
      source: source ?? this.source,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      tags: tags,
      metadonnees: metadonnees,
      actions: actions,
      idUtilisateur: idUtilisateur,
      estRecurrente: estRecurrente,
      configurationRecurrence: configurationRecurrence,
    );
  }

  /// Convertit l'alerte en Map pour stockage/sérialisation (nouveau modèle)
  Map<String, dynamic> versMap() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'type': type.valeur,
      'statut': statut.valeur,
      'date_creation': dateCreation.toIso8601String(),
      'date_echeance': dateEcheance?.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
      'tags': tags,
      'metadonnees': metadonnees,
      'actions': actions,
      'niveau_priorite': niveauPriorite,
      'id_utilisateur': idUtilisateur,
      'donnees_medicales': donneesMedicales,
      'est_recurrente': estRecurrente,
      'configuration_recurrence': configurationRecurrence,
      'recommandations': recommandations,
      'source': source,
      'date_expiration': dateExpiration?.toIso8601String(),
    };
  }

  /// Convertit le modèle en Map pour stockage en base de données (ancien modèle)
  Map<String, dynamic> versCarte() {
    return {
      'id': id,
      'type': type.valeur,
      'titre': titre,
      'message': description,
      'severite': severite.valeur,
      'horodatage': dateCreation.toIso8601String(),
      'recommandations': recommandations.join('|'),
      'estLu': estLu ? 1 : 0,
      'source': source,
      'donneesMetier': donneesMedicales,
      'dateExpiration': dateExpiration?.toIso8601String(),
      'priorite': priorite,
    };
  }

  /// Crée une alerte depuis une Map (nouveau modèle)
  static ModeleAlerte depuisMap(Map<String, dynamic> map) {
    return ModeleAlerte(
      id: map['id'] as String,
      titre: map['titre'] as String,
      description: map['description'] as String,
      type: TypeAlerte.depuisChaine(map['type'] as String),
      statut: StatutAlerte.depuisChaine(map['statut'] as String? ?? 'nouvelle'),
      dateCreation: DateTime.parse(map['date_creation'] as String),
      dateEcheance: map['date_echeance'] != null 
          ? DateTime.parse(map['date_echeance'] as String) 
          : null,
      dateModification: map['date_modification'] != null
          ? DateTime.parse(map['date_modification'] as String)
          : DateTime.parse(map['date_creation'] as String),
      tags: List<String>.from(map['tags'] ?? []),
      metadonnees: Map<String, dynamic>.from(map['metadonnees'] ?? {}),
      actions: Map<String, String>.from(map['actions'] ?? {}),
      niveauPriorite: map['niveau_priorite'] as int? ?? 50,
      idUtilisateur: map['id_utilisateur'] as String?,
      donneesMedicales: map['donnees_medicales'] != null
          ? Map<String, dynamic>.from(map['donnees_medicales'])
          : null,
      estRecurrente: map['est_recurrente'] as bool? ?? false,
      configurationRecurrence: map['configuration_recurrence'] != null
          ? Map<String, dynamic>.from(map['configuration_recurrence'])
          : null,
      recommandations: List<String>.from(map['recommandations'] ?? []),
      source: map['source'] as String? ?? 'E-Santé 4.0',
      dateExpiration: map['date_expiration'] != null
          ? DateTime.parse(map['date_expiration'] as String)
          : null,
    );
  }

  /// Crée un modèle d'alerte à partir d'une Map (ancien modèle)
  factory ModeleAlerte.depuisCarte(Map<String, dynamic> carte) {
    return ModeleAlerte.depuisAncien(
      id: carte['id'] as String,
      type: TypeAlerte.depuisChaine(carte['type'] as String),
      titre: carte['titre'] as String,
      message: carte['message'] as String,
      severite: NiveauSeverite.depuisChaine(carte['severite'] as String),
      horodatage: DateTime.parse(carte['horodatage'] as String),
      recommandations: (carte['recommandations'] as String? ?? '').split('|')
          .where((s) => s.isNotEmpty).toList(),
      estLu: (carte['estLu'] as int? ?? 0) == 1,
      source: carte['source'] as String? ?? 'E-Santé 4.0',
      donneesMetier: carte['donneesMetier'] as Map<String, dynamic>?,
      dateExpiration: carte['dateExpiration'] != null
          ? DateTime.parse(carte['dateExpiration'] as String)
          : null,
      priorite: carte['priorite'] as int? ?? 5,
    );
  }

  /// Méthodes utilitaires

  /// Vérifie si l'alerte est urgente
  bool get estUrgente => niveauPriorite >= 80;

  /// Vérifie si l'alerte est critique (compatibilité ancien modèle)
  bool estCritique() => severite == NiveauSeverite.critique || 
                        severite == NiveauSeverite.eleve ||
                        type == TypeAlerte.critique;

  /// Vérifie si l'alerte est encore valide (non expirée)
  bool estValide() {
    final expiration = dateExpiration ?? dateEcheance;
    if (expiration == null) return true;
    return DateTime.now().isBefore(expiration);
  }

  /// Vérifie si l'alerte est en retard
  bool get estEnRetard {
    final echeance = dateEcheance ?? dateExpiration;
    if (echeance == null) return false;
    return DateTime.now().isAfter(echeance);
  }

  /// Obtient le délai restant avant échéance
  Duration? get delaiRestant {
    final echeance = dateEcheance ?? dateExpiration;
    if (echeance == null) return null;
    final maintenant = DateTime.now();
    if (maintenant.isAfter(echeance)) return Duration.zero;
    return echeance.difference(maintenant);
  }

  /// Obtient une description textuelle du délai
  String get descriptionDelai {
    final delai = delaiRestant;
    if (delai == null) return 'Pas d\'échéance';
    
    if (delai == Duration.zero) return 'En retard';
    
    if (delai.inDays > 0) {
      return 'Dans ${delai.inDays} jour${delai.inDays > 1 ? 's' : ''}';
    } else if (delai.inHours > 0) {
      return 'Dans ${delai.inHours} heure${delai.inHours > 1 ? 's' : ''}';
    } else {
      return 'Dans ${delai.inMinutes} minute${delai.inMinutes > 1 ? 's' : ''}';
    }
  }

  /// Met à jour le statut de l'alerte
  void mettreAJourStatut(StatutAlerte nouveauStatut) {
    statut = nouveauStatut;
    dateModification = DateTime.now();
  }

  /// Marque l'alerte comme lue
  void marquerCommeLue() {
    if (statut == StatutAlerte.nouvelle) {
      mettreAJourStatut(StatutAlerte.lue);
    }
  }

  /// Vérifie si l'alerte correspond à une requête de recherche
  bool correspondARecherche(String requete) {
    final requeteBasse = requete.toLowerCase();
    return titre.toLowerCase().contains(requeteBasse) ||
           description.toLowerCase().contains(requeteBasse) ||
           type.libelle.toLowerCase().contains(requeteBasse) ||
           tags.any((tag) => tag.toLowerCase().contains(requeteBasse)) ||
           recommandations.any((rec) => rec.toLowerCase().contains(requeteBasse));
  }

  /// Vérifie si l'alerte a un tag spécifique
  bool aTag(String tag) => tags.contains(tag);

  /// Ajoute un tag à l'alerte
  void ajouterTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      dateModification = DateTime.now();
    }
  }

  /// Supprime un tag de l'alerte
  void supprimerTag(String tag) {
    if (tags.remove(tag)) {
      dateModification = DateTime.now();
    }
  }

  /// Retourne la couleur associée au niveau de sévérité (ancien modèle)
  String obtenirCouleurSeverite() {
    return '#${severite.couleur.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Retourne l'icône appropriée selon le type d'alerte (ancien modèle)
  String obtenirIconeType() {
    return type.emoji;
  }

  /// Génère un résumé court de l'alerte pour les notifications (ancien modèle)
  String obtenirResume() {
    return '${type.emoji} $titre - ${severite.libelle.toUpperCase()}';
  }

  /// Compare deux alertes pour le tri par priorité et date (ancien modèle)
  int comparerAvec(ModeleAlerte autre) {
    // D'abord par priorité (plus petit = plus prioritaire pour ancien modèle)
    int comparaisonPriorite = priorite.compareTo(autre.priorite);
    if (comparaisonPriorite != 0) return comparaisonPriorite;
    
    // Ensuite par sévérité (critique en premier)
    int comparaisonSeverite = autre.severite.index.compareTo(severite.index);
    if (comparaisonSeverite != 0) return comparaisonSeverite;
    
    // Enfin par date (plus récent en premier)
    return autre.dateCreation.compareTo(dateCreation);
  }

  @override
  String toString() {
    return 'ModeleAlerte(id: $id, titre: $titre, type: ${type.libelle}, '
           'statut: ${statut.libelle}, priorité: $niveauPriorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModeleAlerte && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extensions utilitaires pour les listes d'alertes
extension ListeAlerteExtensions on List<ModeleAlerte> {
  /// Filtre les alertes par type
  List<ModeleAlerte> filtrerParType(TypeAlerte type) {
    return where((alerte) => alerte.type == type).toList();
  }

  /// Filtre les alertes par statut
  List<ModeleAlerte> filtrerParStatut(StatutAlerte statut) {
    return where((alerte) => alerte.statut == statut).toList();
  }

  /// Filtre les alertes par sévérité (compatibilité ancien modèle)
  List<ModeleAlerte> filtrerParSeverite(NiveauSeverite severite) {
    return where((alerte) => alerte.severite == severite).toList();
  }

  /// Filtre les alertes urgentes
  List<ModeleAlerte> filtrerUrgentes() {
    return where((alerte) => alerte.estUrgente).toList();
  }

  /// Filtre les alertes en retard
  List<ModeleAlerte> filtrerEnRetard() {
    return where((alerte) => alerte.estEnRetard).toList();
  }

  /// Filtre les alertes lues (compatibilité ancien modèle)
  List<ModeleAlerte> filtrerLues() {
    return where((alerte) => alerte.estLu).toList();
  }

  /// Filtre les alertes non lues (compatibilité ancien modèle)
  List<ModeleAlerte> filtrerNonLues() {
    return where((alerte) => !alerte.estLu).toList();
  }

  /// Trie les alertes par priorité (décroissante)
  List<ModeleAlerte> trierParPriorite() {
    final copie = List<ModeleAlerte>.from(this);
    copie.sort((a, b) => b.niveauPriorite.compareTo(a.niveauPriorite));
    return copie;
  }

  /// Trie les alertes par date d'échéance
  List<ModeleAlerte> trierParEcheance() {
    final copie = List<ModeleAlerte>.from(this);
    copie.sort((a, b) {
      final echeanceA = a.dateEcheance ?? a.dateExpiration;
      final echeanceB = b.dateEcheance ?? b.dateExpiration;
      
      if (echeanceA == null && echeanceB == null) return 0;
      if (echeanceA == null) return 1;
      if (echeanceB == null) return -1;
      return echeanceA.compareTo(echeanceB);
    });
    return copie;
  }

  /// Recherche dans les alertes
  List<ModeleAlerte> rechercher(String requete) {
    if (requete.isEmpty) return this;
    return where((alerte) => alerte.correspondARecherche(requete)).toList();
  }

  /// Obtient les statistiques de la liste
  Map<String, int> obtenirStatistiques() {
    return {
      'total': length,
      'nouvelles': filtrerParStatut(StatutAlerte.nouvelle).length,
      'lues': filtrerParStatut(StatutAlerte.lue).length,
      'en_cours': filtrerParStatut(StatutAlerte.enCours).length,
      'resolues': filtrerParStatut(StatutAlerte.resolue).length,
      'urgentes': filtrerUrgentes().length,
      'en_retard': filtrerEnRetard().length,
      'critiques': filtrerParType(TypeAlerte.critique).length,
      'medicaments': filtrerParType(TypeAlerte.medicament).length,
      'rendez_vous': filtrerParType(TypeAlerte.rendezvous).length,
      'ia': filtrerParType(TypeAlerte.ia).length,
      'environnementales': filtrerParType(TypeAlerte.environnementale).length,
      'medicales': filtrerParType(TypeAlerte.medicale).length,
      'manuelles': filtrerParType(TypeAlerte.manuelle).length,
    };
  }
}