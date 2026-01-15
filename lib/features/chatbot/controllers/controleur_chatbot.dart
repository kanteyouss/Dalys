import 'package:flutter/foundation.dart';
import '../../../data/models/message_chatbot.dart';
import '../../../data/services/service_chatbot.dart';
import '../../../data/models/health_data.dart';

/// Contrôleur pour gérer l'état et la logique du chatbot
class ControleurChatbot extends ChangeNotifier {
  final ServiceChatbot _serviceChatbot = ServiceChatbot();
  
  List<MessageChatbot> _messages = [];
  bool _enTrainDeEcrire = false;
  HealthData? _donneesVitalesActuelles;

  /// Getters
  List<MessageChatbot> get messages => List.unmodifiable(_messages);
  bool get enTrainDeEcrire => _enTrainDeEcrire;
  
  /// Définir les données de santé actuelles pour des réponses contextuelles
  void definirDonneesSante(HealthData? donnees) {
    _donneesVitalesActuelles = donnees;
  }

  /// Initialise le chatbot et charge l'historique
  Future<void> initialiser() async {
    _messages = await _serviceChatbot.initialiser();
    
    if (_messages.isEmpty) {
      final messageBienvenue = MessageChatbot.assistant(
        'Bonjour ! Je suis votre assistant santé personnel. '
        'Je peux analyser vos symptômes et vous donner des conseils. '
        'Comment vous sentez-vous aujourd\'hui ?',
        quickReplies: [
          'Je vais bien',
          'J\'ai des symptômes',
          'Mes données vitales',
        ],
      );
      _messages.add(messageBienvenue);
      // On ne sauvegarde pas le message de bienvenue initial s'il est généré localement, 
      // ou alors on devrait le faire via le service. 
      // Pour l'instant on laisse comme ça pour l'affichage.
    }
    notifyListeners();
  }

  /// Envoie un message utilisateur et obtient une réponse
  Future<void> envoyerMessage(String texte) async {
    if (texte.trim().isEmpty) return;

    // Ajouter le message utilisateur localement pour affichage immédiat
    final messageUtilisateur = MessageChatbot.user(texte.trim());
    _messages.add(messageUtilisateur);
    notifyListeners();

    // Afficher l'indicateur de frappe
    _enTrainDeEcrire = true;
    notifyListeners();

    try {
      // Générer la réponse du chatbot via le service
      final reponse = await _serviceChatbot.genererReponse(
        texte,
        donneesVitales: _donneesVitalesActuelles,
      );

      // Ajouter la réponse
      _messages.add(reponse);
    } catch (e) {
      // En cas d'erreur
      _messages.add(MessageChatbot.assistant(
        'Désolé, une erreur est survenue. Veuillez réessayer.',
      ));
      debugPrint('Erreur chatbot: $e');
    } finally {
      _enTrainDeEcrire = false;
      notifyListeners();
    }
  }

  /// Envoie une réponse rapide (quick reply)
  Future<void> envoyerReponseRapide(String reponse) async {
    await envoyerMessage(reponse);
  }

  /// Efface l'historique des messages
  Future<void> effacerHistorique() async {
    await _serviceChatbot.effacerHistorique();
    _messages.clear();
    await initialiser(); // Réinitialiser avec le message de bienvenue
  }

  /// Obtient des suggestions de questions
  List<String> obtenirSuggestions() {
    return _serviceChatbot.obtenirSuggestions();
  }
}
