import 'package:flutter/material.dart';
import '../models/medication_model.dart';

class MedicationService extends ChangeNotifier {
  final List<Medication> _medications = [];

  List<Medication> get medications => List.unmodifiable(_medications);

  MedicationService() {
    // Données simulées pour la démo
    _medications.add(Medication(
      id: '1',
      name: 'Ventoline',
      dosage: '2 bouffées',
      frequencyPerDay: 4,
      schedule: [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 12, minute: 0),
        const TimeOfDay(hour: 16, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ],
      isTakenToday: false,
    ));
    _medications.add(Medication(
      id: '2',
      name: 'Seretide',
      dosage: '1 bouffée',
      frequencyPerDay: 2,
      schedule: [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ],
      isTakenToday: true,
    ));
  }

  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
  }

  void removeMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void toggleTaken(String id) {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = _medications[index];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (med.isTakenToday) {
        // Annuler la prise
        med.isTakenToday = false;
        med.history.removeWhere((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);
      } else {
        // Valider la prise
        med.isTakenToday = true;
        med.history.add(today);
      }
      notifyListeners();
    }
  }

  // Méthode pour vérifier si un médicament a été pris à une date donnée
  bool isTakenOn(String id, DateTime date) {
    final med = _medications.firstWhere((m) => m.id == id,
        orElse: () => Medication(
            id: '',
            name: '',
            dosage: '',
            frequencyPerDay: 0,
            schedule: [],
            history: {}));
    if (med.id.isEmpty) return false;

    return med.history.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  double get adherenceRate {
    if (_medications.isEmpty) return 1.0;
    final takenCount = _medications.where((m) => m.isTakenToday).length;
    return takenCount / _medications.length;
  }
}
