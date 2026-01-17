import 'package:flutter/material.dart';
import '../../../data/models/health_data.dart';
import '../../../data/models/user_model.dart';
import '../../alertes/widgets/emergency_countdown_overlay.dart';

/// Écran en mode urgence - Interface épurée et rassurante
class CriticalModeScreen extends StatefulWidget {
  final HealthData currentData;
  final UserModel user;
  final VoidCallback onReturn;

  const CriticalModeScreen({
    Key? key,
    required this.currentData,
    required this.user,
    required this.onReturn,
  }) : super(key: key);

  @override
  State<CriticalModeScreen> createState() => _CriticalModeScreenState();
}

class _CriticalModeScreenState extends State<CriticalModeScreen> {
  void _triggerEmergency() {
    EmergencyCountdownOverlay.show(
      context,
      widget.user,
      _getEmergencyDescription(),
    );
  }

  String _getEmergencyDescription() {
    final issues = <String>[];
    if (widget.currentData.spo2 < 90) {
      issues.add('Oxygène bas (${widget.currentData.spo2}%)');
    }
    if (widget.currentData.breathingRate > 28) {
      issues.add('Respiration rapide (${widget.currentData.breathingRate} /min)');
    }
    if (widget.currentData.pef < 250) {
      issues.add('Souffle faible (${widget.currentData.pef.toInt()} L/min)');
    }
    return issues.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Demander confirmation avant de quitter le mode critique
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter le mode alerte ?'),
            content: const Text(
              'Êtes-vous sûr(e) de vous sentir mieux ?\n\n'
              'Si vous avez encore des difficultés respiratoires, '
              'restez sur cet écran et appelez les urgences.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Rester'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Oui, je vais mieux'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône d'alerte
                Icon(
                  Icons.warning_amber_rounded,
                  size: 120,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  'ALERTE SANTÉ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description simple
                Text(
                  _getCriticalMessage(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // BOUTON SOS GÉANT
                GestureDetector(
                  onTap: _triggerEmergency,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade700,
                          Colors.red.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_in_talk,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'APPELER',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'URGENCE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton secondaire : Exercice respiration
                ElevatedButton.icon(
                  onPressed: _showBreathingExercise,
                  icon: const Icon(Icons.air),
                  label: const Text(
                    'Exercice Respiration Guidé',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Instructions simples
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'En attendant :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('1', 'Asseyez-vous confortablement'),
                      const SizedBox(height: 8),
                      _buildInstruction('2', 'Respirez lentement et profondément'),
                      const SizedBox(height: 8),
                      _buildInstruction('3', 'Restez calme, l\'aide arrive'),
                    ],
                  ),
                ),
                const Spacer(),

                // Bouton discret pour quitter
                TextButton(
                  onPressed: widget.onReturn,
                  child: Text(
                    'Je me sens mieux maintenant',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  String _getCriticalMessage() {
    if (widget.currentData.spo2 < 90) {
      return 'Votre niveau d\'oxygène est bas (${widget.currentData.spo2}%).\n'
          'Vous avez besoin d\'aide rapidement.';
    }
    if (widget.currentData.breathingRate > 28) {
      return 'Votre respiration est très rapide (${widget.currentData.breathingRate}/min).\n'
          'Prenez quelques respirations profondes.';
    }
    if (widget.currentData.pef < 250) {
      return 'Votre souffle est très faible.\n'
          'Asseyez-vous et reposez-vous.';
    }
    return 'Vos paramètres vitaux nécessitent une attention immédiate.';
  }

  void _showBreathingExercise() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.air,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Exercice de Respiration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Inspirez par le nez pendant 4 secondes\n\n'
                '2. Retenez votre souffle 2 secondes\n\n'
                '3. Expirez par la bouche pendant 6 secondes\n\n'
                '4. Répétez 5 fois',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Commencer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
