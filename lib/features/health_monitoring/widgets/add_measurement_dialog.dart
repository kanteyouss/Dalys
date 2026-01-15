import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';

class AddMeasurementDialog extends StatefulWidget {
  const AddMeasurementDialog({super.key});

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _spo2Controller = TextEditingController();
  final _breathingRateController = TextEditingController();
  final _pefController = TextEditingController();

  final List<String> _selectedSymptoms = [];
  final List<String> _availableSymptoms = [
    'Toux sèche',
    'Toux grasse',
    'Essoufflement',
    'Fatigue',
    'Douleur thoracique',
    'Fièvre légère',
    'Mal de gorge',
    'Congestion nasale',
    'Oppression thoracique',
  ];

  @override
  void dispose() {
    _spo2Controller.dispose();
    _breathingRateController.dispose();
    _pefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nouvelle mesure',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Paramètres vitaux
                _buildSectionTitle(context, 'Paramètres vitaux'),
                const SizedBox(height: 16),

                // SpO2
                _buildTextField(
                  controller: _spo2Controller,
                  label: 'Saturation en oxygène (SpO₂)',
                  suffix: '%',
                  hint: 'Ex: 98',
                  icon: Icons.favorite,
                  info: 'Mesure l\'oxygène dans le sang. Normal: 95-100%.',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final spo2 = int.tryParse(value);
                    if (spo2 == null || spo2 < 70 || spo2 > 100)
                      return 'Invalide (70-100%)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fréquence respiratoire
                _buildTextField(
                  controller: _breathingRateController,
                  label: 'Fréquence respiratoire',
                  suffix: 'bpm',
                  hint: 'Ex: 18',
                  icon: Icons.air,
                  info: 'Nombre de respirations par minute. Normal: 12-20 bpm.',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final rate = int.tryParse(value);
                    if (rate == null || rate < 8 || rate > 40)
                      return 'Invalide (8-40 bpm)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Débit de pointe
                _buildTextField(
                  controller: _pefController,
                  label: 'Débit de pointe (PEF)',
                  suffix: 'L/min',
                  hint: 'Ex: 400',
                  icon: Icons.timeline,
                  info: 'Vitesse maximale d\'expiration. Évalue le souffle.',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requis';
                    final pef = double.tryParse(value);
                    if (pef == null || pef < 100 || pef > 800)
                      return 'Invalide (100-800)';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Symptômes
                _buildSectionTitle(context, 'Symptômes (optionnel)'),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSymptoms.map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom);
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                      selectedColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveMeasurement,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String hint,
    required IconData icon,
    required String info,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: label,
                  suffixText: suffix,
                  hintText: hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(icon),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: validator,
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              onPressed: () => _showInfo(label, info),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _saveMeasurement() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final spo2 = int.parse(_spo2Controller.text);
      final breathingRate = int.parse(_breathingRateController.text);
      final pef = double.parse(_pefController.text);

      context.read<HealthController>().addManualMeasurement(
            spo2: spo2,
            breathingRate: breathingRate,
            pef: pef,
            symptoms: _selectedSymptoms,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Mesure enregistrée avec succès !'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop();
    } else {
      HapticFeedback.vibrate();
    }
  }
}
