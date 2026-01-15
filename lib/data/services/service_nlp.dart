import '../models/donnees_symptomes.dart';

/// Service NLP local pour l'extraction de symptômes en français
/// Fonctionne hors ligne sans API externe
class ServiceNLP {
  static final ServiceNLP _instance = ServiceNLP._internal();
  factory ServiceNLP() => _instance;
  ServiceNLP._internal();

  // Dictionnaire de symptômes et leurs synonymes
  final Map<String, List<String>> _dictionnaireSymptomes = {
    'toux': ['toux', 'tousser', 'tousse', 'crachat', 'glaires'],
    'essoufflement': ['essoufflement', 'souffle', 'respiration', 'dyspnée', 'air', 'étouffe'],
    'fatigue': ['fatigue', 'épuisé', 'las', 'crevé', 'faible', 'énergie'],
    'fievre': ['fièvre', 'température', 'chaud', 'frisson', 'suer'],
    'douleur_thoracique': ['douleur', 'poitrine', 'thorax', 'cœur', 'serre', 'pique'],
    'sifflements': ['sifflement', 'siffle', 'bruit'],
    'oppression': ['oppression', 'poids', 'lourd'],
    'maux_tete': ['tête', 'migraine', 'céphalée'],
  };

  // Mots-clés de sévérité
  final Map<String, List<String>> _dictionnaireSeverite = {
    'fort': ['très', 'fort', 'grave', 'intense', 'insupportable', 'beaucoup', 'énorme', 'terrible'],
    'moyen': ['moyen', 'assez', 'peu', 'modéré', 'gênant'],
    'leger': ['léger', 'petit', 'fable', 'juste', 'un peu'],
  };

  // Mots-clés de négation
  final List<String> _negations = ['pas', 'non', 'aucun', 'jamais', 'rien', 'ni'];

  /// Analyse le texte utilisateur pour extraire les symptômes
  DonneesSymptomes extraireSymptomes(String texte) {
    final texteMinuscule = texte.toLowerCase();
    final List<ElementSymptome> symptomesDetectes = [];
    String severiteGlobale = 'leger';
    int scoreSeverite = 0;

    // Détection des symptômes
    _dictionnaireSymptomes.forEach((cleSymptome, synonymes) {
      if (_contientSymptome(texteMinuscule, synonymes) && !_estNegation(texteMinuscule, synonymes)) {
        // Déterminer la sévérité spécifique pour ce symptôme
        final severiteLocale = _detecterSeveriteLocale(texteMinuscule, synonymes);
        
        symptomesDetectes.add(ElementSymptome(
          nom: cleSymptome,
          severite: severiteLocale,
          metadonnees: {'detecte_via': 'nlp_local'},
        ));

        // Mise à jour du score global
        if (severiteLocale == 'fort') scoreSeverite += 3;
        else if (severiteLocale == 'moyen') scoreSeverite += 2;
        else scoreSeverite += 1;
      }
    });

    // Calcul sévérité globale
    if (scoreSeverite >= 5 || _contientMotCle(texteMinuscule, _dictionnaireSeverite['fort']!)) {
      severiteGlobale = 'fort';
    } else if (scoreSeverite >= 3 || _contientMotCle(texteMinuscule, _dictionnaireSeverite['moyen']!)) {
      severiteGlobale = 'moyen';
    }

    return DonneesSymptomes(
      horodatage: DateTime.now(),
      symptomes: symptomesDetectes,
      severiteGlobale: severiteGlobale,
      texteBrut: texte,
      confiance: 0.85, // Score fixe pour le prototype
    );
  }

  /// Vérifie si le texte contient un des synonymes
  bool _contientSymptome(String texte, List<String> synonymes) {
    return synonymes.any((mot) => texte.contains(mot));
  }

  /// Vérifie si le symptôme est nié (ex: "je ne tousse pas")
  bool _estNegation(String texte, List<String> synonymes) {
    // Logique simplifiée : cherche une négation proche du symptôme
    // Pourrait être amélioré avec une analyse syntaxique plus poussée
    for (final synonyme in synonymes) {
      final index = texte.indexOf(synonyme);
      if (index != -1) {
        // Regarder les 20 caractères précédents
        final debut = (index - 20) < 0 ? 0 : index - 20;
        final contexte = texte.substring(debut, index);
        if (_negations.any((neg) => contexte.contains(neg))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Détecte la sévérité associée à un symptôme spécifique
  String? _detecterSeveriteLocale(String texte, List<String> synonymes) {
    // Cherche des mots de sévérité autour du symptôme
    for (final synonyme in synonymes) {
      final index = texte.indexOf(synonyme);
      if (index != -1) {
        final debut = (index - 30) < 0 ? 0 : index - 30;
        final fin = (index + 30) > texte.length ? texte.length : index + 30;
        final contexte = texte.substring(debut, fin);

        if (_contientMotCle(contexte, _dictionnaireSeverite['fort']!)) return 'fort';
        if (_contientMotCle(contexte, _dictionnaireSeverite['moyen']!)) return 'moyen';
        if (_contientMotCle(contexte, _dictionnaireSeverite['leger']!)) return 'leger';
      }
    }
    return null;
  }

  bool _contientMotCle(String texte, List<String> motsCles) {
    return motsCles.any((mot) => texte.contains(mot));
  }
}
