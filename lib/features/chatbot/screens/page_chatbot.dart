import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../data/models/message_chatbot.dart';
import '../../../../data/models/health_data.dart';
import '../../../../data/services/service_chatbot.dart';
import '../../../../data/services/service_vocal.dart';
import '../../../../data/models/modele_alerte.dart';
import '../../health_monitoring/controllers/health_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Écran principal du chatbot
class PageChatbot extends StatefulWidget {
  const PageChatbot({super.key});

  @override
  State<PageChatbot> createState() => _PageChatbotState();
}

class _PageChatbotState extends State<PageChatbot> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ServiceChatbot _serviceChatbot = ServiceChatbot();
  final ServiceVocal _serviceVocal = ServiceVocal();

  List<MessageChatbot> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initialiserChat();
    _initialiserVocal();
  }

  Future<void> _initialiserChat() async {
    final historique = await _serviceChatbot.initialiser();
    setState(() {
      _messages = historique;
      _suggestions = _serviceChatbot.obtenirSuggestions();
    });
    _scrollToBottom();
  }

  Future<void> _initialiserVocal() async {
    await _serviceVocal.initialiser();
    _serviceVocal.onStatus = (status) {
      if (status == 'done' || status == 'notListening') {
        setState(() => _isListening = false);
      }
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyerMessage(String texte) async {
    if (texte.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    _textController.clear();
    setState(() {
      _messages.add(MessageChatbot.user(texte));
      _isTyping = true;
      _suggestions = [];
    });
    _scrollToBottom();

    final healthController = context.read<HealthController>();
    final donneesVitales = healthController.currentHealthData;

    try {
      final reponse = await _serviceChatbot.genererReponse(
        texte,
        donneesVitales: donneesVitales,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isTyping = false;
          _messages.add(reponse);
          if (reponse.quickReplies != null) {
            _suggestions = reponse.quickReplies!;
          } else {
            _suggestions = _serviceChatbot.obtenirSuggestions();
          }
        });
        _scrollToBottom();

        if (reponse.text.length < 200) {
          _serviceVocal.parler(reponse.text,
              niveau: NiveauNotification.prevention);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() {
          _isTyping = false;
          _messages.add(MessageChatbot.assistant(
            "Désolé, j'ai rencontré une erreur. Pouvez-vous répéter ?",
          ));
        });
      }
    }
  }

  void _envoyerReponseRapide(String reponse) {
    HapticFeedback.selectionClick();
    _envoyerMessage(reponse);
  }

  void _basculerEcoute() async {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _serviceVocal.arreterEcoute();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _serviceVocal.ecouter(
        onResult: (texte) {
          _envoyerMessage(texte);
          setState(() => _isListening = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 18,
              child: Icon(Icons.smart_toy, size: 22, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Assistant DALYS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer l\'historique',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Effacer l\'historique ?'),
                  content: const Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ANNULER')),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        _serviceChatbot.effacerHistorique();
                        setState(() => _messages.clear());
                        Navigator.pop(context);
                      },
                      child: const Text('EFFACER',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator();
                }
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(_suggestions[index],
                          style: const TextStyle(fontSize: 13)),
                      onPressed: () =>
                          _envoyerReponseRapide(_suggestions[index]),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  _buildMicButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Écoute...' : 'Message...',
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _envoyerMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: Theme.of(context).primaryColor),
                    onPressed: () => _envoyerMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _basculerEcoute,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isListening
              ? Colors.red.shade100
              : Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? Colors.red : Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
    );
  }
}
