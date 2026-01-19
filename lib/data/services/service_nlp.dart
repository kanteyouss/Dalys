import 'dart:math';
import '../models/donnees_symptomes.dart';

/// Service NLP local pour l'extraction de symptômes en français
/// Fonctionne hors ligne sans API externe
class ServiceNLP {
  static final ServiceNLP _instance = ServiceNLP._internal();
  factory ServiceNLP() => _instance;
  ServiceNLP._internal();

  // Dictionnaire de symptômes et leurs synonymes
  final Map<String, List<String>> _dictionnaireSymptomes = {
    'toux': ['toux', 'tousser', 'tousse', 'crachat', 'glaires', 'gorge'],
    'essoufflement': [
      'essoufflement',
      'souffle',
      'respiration',
      'dyspnée',
      'air',
      'étouffe',
      'etouffe'
    ],
    'fatigue': [
      'fatigue',
      'épuisé',
      'las',
      'crevé',
      'faible',
      'énergie',
      'hs',
      'ko'
    ],
    'fievre': [
      'fièvre',
      'température',
      'chaud',
      'frisson',
      'suer',
      'transpire'
    ],
    'douleur_thoracique': [
      'douleur',
      'poitrine',
      'thorax',
      'cœur',
      'serre',
      'pique',
      'mal',
      'bobo',
      'souffre'
    ],
    'sifflements': ['sifflement', 'siffle', 'bruit'],
    'oppression': ['oppression', 'poids', 'lourd'],
    'maux_tete': ['tête', 'migraine', 'céphalée', 'crane', 'tempes'],
    'maux_ventre': ['ventre', 'estomac', 'digestion', 'nausée', 'bide'],
  };

  // Mots-clés d'intention générale
  final Map<String, List<String>> _dictionnaireIntentions = {
    'oui': [
      'oui',
      'ouais',
      'yes',
      'ok',
      'd\'accord',
      'absolument',
      'yep',
      'si'
    ],
    'non': ['non', 'nan', 'no', 'pas du tout', 'nope'],
    'merci': ['merci', 'remercie', 'cimer', 'top', 'super', 'cool', 'génial'],
  };

  // Mots-clés de sévérité
  final Map<String, List<String>> _dictionnaireSeverite = {
    'fort': [
      'très',
      'fort',
      'grave',
      'intense',
      'insupportable',
      'beaucoup',
      'énorme',
      'terrible'
    ],
    'moyen': ['moyen', 'assez', 'peu', 'modéré', 'gênant'],
    'leger': ['léger', 'petit', 'fable', 'juste', 'un peu'],
  };

  // Mots-clés de négation
  final List<String> _negations = [
    'pas',
    'non',
    'aucun',
    'jamais',
    'rien',
    'ni'
  ];

  /// Analyse le texte utilisateur pour extraire les symptômes
  DonneesSymptomes extraireSymptomes(String texte) {
    final texteMinuscule = texte.toLowerCase();
    final List<ElementSymptome> symptomesDetectes = [];
    String severiteGlobale = 'leger';
    int scoreSeverite = 0;

    // Détection des symptômes
    _dictionnaireSymptomes.forEach((cleSymptome, synonymes) {
      if (_contientSymptome(texteMinuscule, synonymes) &&
          !_estNegation(texteMinuscule, synonymes)) {
        // Déterminer la sévérité spécifique pour ce symptôme
        final severiteLocale =
            _detecterSeveriteLocale(texteMinuscule, synonymes);

        symptomesDetectes.add(ElementSymptome(
          nom: cleSymptome,
          severite: severiteLocale,
          metadonnees: {'detecte_via': 'nlp_local'},
        ));

        // Mise à jour du score global
        if (severiteLocale == 'fort')
          scoreSeverite += 3;
        else if (severiteLocale == 'moyen')
          scoreSeverite += 2;
        else
          scoreSeverite += 1;
      }
    });

    // Calcul sévérité globale
    if (scoreSeverite >= 5 ||
        _contientMotCle(texteMinuscule, _dictionnaireSeverite['fort']!)) {
      severiteGlobale = 'fort';
    } else if (scoreSeverite >= 3 ||
        _contientMotCle(texteMinuscule, _dictionnaireSeverite['moyen']!)) {
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

  /// Détecte une intention générale (oui, non, merci)
  String? detecterIntention(String texte) {
    final texteMinuscule = texte.toLowerCase();

    for (var entry in _dictionnaireIntentions.entries) {
      if (_contientSymptome(texteMinuscule, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Vérifie si le texte contient un des synonymes avec tolérance aux fautes
  bool _contientSymptome(String texte, List<String> synonymes) {
    final motsTexte = texte.split(RegExp(r'[ \.,;\?!]+'));

    for (final synonyme in synonymes) {
      // 1. Recherche exacte
      if (texte.contains(synonyme)) return true;

      // 2. Recherche floue (fuzzy) mot par mot
      for (final mot in motsTexte) {
        if (mot.length < 3) continue; // Ignorer les mots trop courts

        final distance = _levenshtein(mot, synonyme);
        final seuil = synonyme.length <= 4 ? 1 : 2;

        if (distance <= seuil) return true;
      }
    }
    return false;
  }

  /// Calcule la distance de Levenshtein entre deux chaînes
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) v0[i] = i;

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }

    return v1[t.length];
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

        if (_contientMotCle(contexte, _dictionnaireSeverite['fort']!))
          return 'fort';
        if (_contientMotCle(contexte, _dictionnaireSeverite['moyen']!))
          return 'moyen';
        if (_contientMotCle(contexte, _dictionnaireSeverite['leger']!))
          return 'leger';
      }
    }
    return null;
  }

  bool _contientMotCle(String texte, List<String> motsCles) {
    return motsCles.any((mot) => texte.contains(mot));
  }
}
