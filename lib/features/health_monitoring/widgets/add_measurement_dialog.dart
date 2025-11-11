import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(16),
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
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nouvelle mesure',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                Text(
                  'Paramètres vitaux',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // SpO2
                TextFormField(
                  controller: _spo2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saturation en oxygène (SpO₂)',
                    suffixText: '%',
                    hintText: 'Ex: 98',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.favorite),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la valeur SpO₂';
                    }
                    final spo2 = int.tryParse(value);
                    if (spo2 == null || spo2 < 70 || spo2 > 100) {
                      return 'Valeur invalide (70-100%)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fréquence respiratoire
                TextFormField(
                  controller: _breathingRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence respiratoire',
                    suffixText: 'bpm',
                    hintText: 'Ex: 18',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.air),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la fréquence respiratoire';
                    }
                    final rate = int.tryParse(value);
                    if (rate == null || rate < 8 || rate > 40) {
                      return 'Valeur invalide (8-40 bpm)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Débit de pointe
                TextFormField(
                  controller: _pefController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Débit de pointe (PEF)',
                    suffixText: 'L/min',
                    hintText: 'Ex: 400',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le débit de pointe';
                    }
                    final pef = double.tryParse(value);
                    if (pef == null || pef < 100 || pef > 800) {
                      return 'Valeur invalide (100-800 L/min)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Symptômes
                Text(
                  'Symptômes ressentis (optionnel)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
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
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveMeasurement,
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

  void _saveMeasurement() {
    if (_formKey.currentState!.validate()) {
      final spo2 = int.parse(_spo2Controller.text);
      final breathingRate = int.parse(_breathingRateController.text);
      final pef = double.parse(_pefController.text);

      // Ajouter la mesure via le contrôleur
      context.read<HealthController>().addManualMeasurement(
        spo2: spo2,
        breathingRate: breathingRate,
        pef: pef,
        symptoms: _selectedSymptoms,
      );

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Mesure enregistrée avec succès !'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      Navigator.of(context).pop();
    }
  }
}