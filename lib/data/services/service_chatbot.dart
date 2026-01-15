import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/message_chatbot.dart';
import '../models/health_data.dart';
import '../models/entree_symptome_quotidien.dart';
import '../models/donnees_symptomes.dart';
import 'service_nlp.dart';
import 'service_prediction_ia.dart';
import '../repositories/depot_symptomes.dart';
import 'service_historique_chat.dart';
import 'auth_service.dart';

/// Service gérant la logique du chatbot médical
/// Intègre NLP, IA et persistance
class ServiceChatbot {
  static final ServiceChatbot _instance = ServiceChatbot._internal();
  factory ServiceChatbot() => _instance;
  ServiceChatbot._internal();

  final Random _random = Random();
  final ServiceNLP _serviceNLP = ServiceNLP();
  final ServicePredictionIA _serviceIA = ServicePredictionIA();
  final DepotSymptomes _depotSymptomes = DepotSymptomes();
  final ServiceHistoriqueChat _serviceHistorique = ServiceHistoriqueChat();
  final AuthService _authService = AuthService();

  // État de la conversation pour le flux de collecte de symptômes
  bool _enModeCollecte = false;
  List<String> _symptomesCollectes = [];
  String _severiteCollectee = 'leger';

  int? get _currentUserId => _authService.currentUser?.id;

  /// Initialise le service et charge l'historique
  Future<List<MessageChatbot>> initialiser() async {
    final userId = _currentUserId;
    if (userId == null) return [];
    return await _serviceHistorique.recupererHistorique(userId);
  }

  /// Génère une réponse basée sur le message de l'utilisateur
  Future<MessageChatbot> genererReponse(
    String messageUtilisateur, {
    HealthData? donneesVitales,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return MessageChatbot.assistant(
          'Veuillez vous connecter pour utiliser le chatbot.');
    }

    // Sauvegarder le message utilisateur
    final messageUser = MessageChatbot.user(messageUtilisateur);
    await _serviceHistorique.sauvegarderMessage(messageUser, userId);

    // Simulation de latence
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    MessageChatbot reponse;

    if (_enModeCollecte) {
      reponse =
          await _gererFluxCollecte(messageUtilisateur, donneesVitales, userId);
    } else {
      reponse =
          await _gererConversationGenerale(messageUtilisateur, donneesVitales);
    }

    // Sauvegarder la réponse
    await _serviceHistorique.sauvegarderMessage(reponse, userId);
    return reponse;
  }

  /// Gère le flux de conversation générale
  Future<MessageChatbot> _gererConversationGenerale(
    String message,
    HealthData? donneesVitales,
  ) async {
    final messageMinuscule = message.toLowerCase();

    // 1. Détection d'intention de suivi de symptômes
    if (_contientMotCle(messageMinuscule,
        ['symptome', 'mal', 'douleur', 'sentir', 'sensation', 'va pas'])) {
      _enModeCollecte = true;
      _symptomesCollectes = [];
      return MessageChatbot.assistant(
        'Je peux vous aider à analyser vos symptômes. Dites-moi ce que vous ressentez aujourd\'hui ?',
        quickReplies: ['Toux', 'Essoufflement', 'Fatigue', 'Fièvre'],
      );
    }

    // 2. Salutations
    if (_contientMotCle(
        messageMinuscule, ['bonjour', 'salut', 'hello', 'coucou'])) {
      return MessageChatbot.assistant(
        'Bonjour ! Je suis votre assistant santé DALYS. Comment puis-je vous aider ?',
        quickReplies: ['Mes symptômes', 'Données vitales', 'Conseils'],
      );
    }

    // 3. Demande de données vitales
    if (_contientMotCle(
        messageMinuscule, ['donnée', 'mesure', 'spo2', 'coeur', 'tension'])) {
      if (donneesVitales != null) {
        return MessageChatbot.healthCard(
          donneesVitales,
          text: 'Voici vos dernières mesures analysées :',
        );
      } else {
        return MessageChatbot.assistant(
          'Je n\'ai pas encore de données vitales. Veuillez prendre une mesure avec vos capteurs.',
        );
      }
    }

    // 4. Conseils généraux
    if (_contientMotCle(
        messageMinuscule, ['conseil', 'aide', 'recommandation'])) {
      return MessageChatbot.assistant(
        'Voici quelques conseils pour votre santé respiratoire :\n'
        '• Aérez votre logement 10 min par jour\n'
        '• Hydratez-vous régulièrement\n'
        '• Évitez les efforts intenses en cas de pollution',
        quickReplies: ['Mes symptômes', 'Urgence'],
      );
    }

    // 5. Urgence
    if (_contientMotCle(
        messageMinuscule, ['urgence', 'grave', 'mourir', 'secours', 'aide'])) {
      return MessageChatbot.assistant(
        '🚨 URGENCE : Si vous avez des difficultés respiratoires graves, appelez immédiatement le 15 (SAMU) ou le 112.',
      );
    }

    // Réponse par défaut avec analyse NLP légère
    final analyse = _serviceNLP.extraireSymptomes(message);
    if (analyse.aSymptomes) {
      _enModeCollecte = true;
      _symptomesCollectes = analyse.nomsSymptomes;
      return MessageChatbot.assistant(
        'J\'ai noté les symptômes suivants : ${analyse.nomsSymptomes.join(", ")}. '
        'Quelle est l\'intensité de ces symptômes ?',
        quickReplies: ['Léger', 'Moyen', 'Fort'],
      );
    }

    return MessageChatbot.assistant(
      'Je ne suis pas sûr de comprendre. Voulez-vous faire un point sur vos symptômes ?',
      quickReplies: ['Oui, mes symptômes', 'Non, autre chose'],
    );
  }

  /// Gère le flux spécifique de collecte de symptômes
  Future<MessageChatbot> _gererFluxCollecte(
    String message,
    HealthData? donneesVitales,
    int userId,
  ) async {
    final messageMinuscule = message.toLowerCase();

    // Étape 1 : Si on n'a pas encore de symptômes, on essaie de les extraire
    if (_symptomesCollectes.isEmpty) {
      final analyse = _serviceNLP.extraireSymptomes(message);
      if (analyse.aSymptomes) {
        _symptomesCollectes = analyse.nomsSymptomes;
        return MessageChatbot.assistant(
          'C\'est noté. Comment évaluez-vous la sévérité globale ?',
          quickReplies: ['Léger', 'Moyen', 'Fort'],
        );
      } else {
        // Si c'est une réponse rapide
        if (['toux', 'essoufflement', 'fatigue', 'fièvre'].contains(message)) {
          _symptomesCollectes.add(message.toLowerCase());
          return MessageChatbot.assistant(
            'D\'accord. Avez-vous d\'autres symptômes ? Sinon, indiquez la sévérité.',
            quickReplies: ['Non, c\'est tout', 'Léger', 'Moyen', 'Fort'],
          );
        }
        return MessageChatbot.assistant(
          'Pouvez-vous décrire vos symptômes plus précisément ? (ex: "Je tousse beaucoup")',
        );
      }
    }

    // Étape 2 : Détermination de la sévérité
    if (_contientMotCle(messageMinuscule, ['leger', 'faible', 'petit'])) {
      _severiteCollectee = 'leger';
    } else if (_contientMotCle(
        messageMinuscule, ['moyen', 'modéré', 'assez'])) {
      _severiteCollectee = 'moyen';
    } else if (_contientMotCle(
        messageMinuscule, ['fort', 'grave', 'intense', 'beaucoup'])) {
      _severiteCollectee = 'fort';
    } else {
      // Si l'utilisateur ajoute d'autres symptômes au lieu de la sévérité
      final analyse = _serviceNLP.extraireSymptomes(message);
      if (analyse.aSymptomes) {
        _symptomesCollectes.addAll(analyse.nomsSymptomes);
        return MessageChatbot.assistant(
          'J\'ai ajouté ces symptômes. Quelle est la sévérité globale ?',
          quickReplies: ['Léger', 'Moyen', 'Fort'],
        );
      }

      return MessageChatbot.assistant(
        'Merci de préciser la sévérité de vos symptômes.',
        quickReplies: ['Léger', 'Moyen', 'Fort'],
      );
    }

    // Étape 3 : Finalisation et Analyse IA
    _enModeCollecte = false; // Fin du mode collecte

    // Création des objets de données
    final entree = EntreeSymptomeQuotidien.creer(
      userId: userId,
      symptomes: _symptomesCollectes,
      severite: _severiteCollectee,
      notesSupplementaires: message,
    );

    final donneesSymptomes = DonneesSymptomes(
      horodatage: DateTime.now(),
      symptomes:
          _symptomesCollectes.map((s) => ElementSymptome(nom: s)).toList(),
      severiteGlobale: _severiteCollectee,
      texteBrut: message,
    );

    // Sauvegarde
    await _depotSymptomes.sauvegarderEntree(entree);

    // Analyse IA
    final prediction = await _serviceIA.analyserSymptomes(
      symptomes: donneesSymptomes,
      donneesVitales: donneesVitales,
      historique: await _depotSymptomes.recupererHistorique(
        userId: userId,
        debut: DateTime.now().subtract(const Duration(days: 7)),
        fin: DateTime.now(),
      ),
    );

    // Construction de la réponse finale
    String riskLevel = 'low';
    if (prediction.niveauRisque == 'moyen') riskLevel = 'medium';
    if (prediction.niveauRisque == 'eleve') riskLevel = 'high';

    return MessageChatbot.diagnosticCard(
      riskLevel: riskLevel,
      summary: prediction.messageRisque,
      recommendations: prediction.recommandations,
      text: 'J\'ai analysé vos symptômes. Voici le bilan :',
    );
  }

  bool _contientMotCle(String texte, List<String> motsCles) {
    return motsCles.any((mot) => texte.contains(mot));
  }

  /// Envoie un message proactif de la part de l'assistant
  Future<void> envoyerMessageProactif(String texte,
      {List<String>? quickReplies}) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final message = MessageChatbot.assistant(texte, quickReplies: quickReplies);
    await _serviceHistorique.sauvegarderMessage(message, userId);
    debugPrint('🤖 Message proactif envoyé : $texte');
  }

  /// Efface l'historique
  Future<void> effacerHistorique() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _serviceHistorique.effacerHistorique(userId);
  }

  /// Suggestions de questions
  List<String> obtenirSuggestions() {
    return [
      'J\'ai de la fièvre',
      'Je me sens essoufflé',
      'Mes données vitales',
      'Conseils santé',
    ];
  }
}
