import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/message_chatbot.dart';

/// Widget pour afficher une bulle de message dans le chat
class MessageBubble extends StatefulWidget {
  final MessageChatbot message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeFormat = DateFormat('HH:mm');

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.medical_services,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).primaryColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: !isUser &&
                                Theme.of(context).brightness == Brightness.light
                            ? Border.all(color: Colors.grey.shade300, width: 1)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.grey.shade900),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(widget.message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                    // Carte de santé si présente
                    if (widget.message.type == MessageType.healthCard &&
                        widget.message.healthData != null) ...[
                      const SizedBox(height: 8),
                      _HealthCardWidget(data: widget.message.healthData),
                    ],

                    // Carte de diagnostic si présente
                    if (widget.message.type == MessageType.diagnosticCard &&
                        widget.message.diagnosticData != null) ...[
                      const SizedBox(height: 8),
                      _DiagnosticCardWidget(
                          data: widget.message.diagnosticData!),
                    ],

                    // Quick replies si présentes
                    if (widget.message.quickReplies != null &&
                        widget.message.quickReplies!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.message.quickReplies!.map((reply) {
                          return _QuickReplyChip(text: reply);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher une carte de données de santé
class _HealthCardWidget extends StatelessWidget {
  final dynamic data;

  const _HealthCardWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    // On suppose que data est de type HealthData
    // Idéalement on devrait typer fortement, mais pour l'instant on reste dynamique
    // pour éviter les dépendances circulaires trop complexes si HealthData n'est pas dispo ici

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey.shade300
              : Theme.of(context).primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart,
                  size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Signes Vitaux',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildMetricRow(
            context,
            icon: Icons.favorite,
            label: 'SpO₂',
            value: '${data.spo2}%',
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            context,
            icon: Icons.air,
            label: 'Resp.',
            value: '${data.breathingRate} bpm',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            context,
            icon: Icons.speed,
            label: 'PEF',
            value: '${data.pef.toInt()} L/min',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher une carte de diagnostic
class _DiagnosticCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DiagnosticCardWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final riskLevel = data['riskLevel'] as String;
    final summary = data['summary'] as String;
    final recommendations = (data['recommendations'] as List).cast<String>();

    Color riskColor;
    IconData riskIcon;
    String riskLabel;

    switch (riskLevel) {
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.warning;
        riskLabel = 'Risque Élevé';
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        riskLabel = 'Attention Requise';
        break;
      case 'low':
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
        riskLabel = 'Tout va bien';
        break;
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(riskIcon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  riskLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bilan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recommandations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, size: 18, color: riskColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip pour les réponses rapides
class _QuickReplyChip extends StatelessWidget {
  final String text;

  const _QuickReplyChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        // L'action sera gérée par le parent (ChatbotPage)
        // On utilise un callback via le contexte
      },
      backgroundColor: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
