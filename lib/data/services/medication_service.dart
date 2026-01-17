import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../../features/alertes/services/service_notifications.dart';
import '../models/modele_alerte.dart';

class MedicationService extends ChangeNotifier {
  final List<Medication> _medications = [];
  final ServiceNotifications _notificationService = ServiceNotifications();

  List<Medication> get medications => List.unmodifiable(_medications);

  MedicationService() {
    // Initialiser le service de notifications
    _notificationService.initialiser();

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
      isCritical: true,
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

    // Programmer les notifications pour les médicaments existants
    _scheduleAllNotifications();
  }

  void _scheduleAllNotifications() {
    for (var med in _medications) {
      _scheduleMedicationNotifications(med);
    }
  }

  void _scheduleMedicationNotifications(Medication med) {
    final now = DateTime.now();

    // Vérifier si le traitement est en cours
    if (med.startDate != null && med.startDate!.isAfter(now)) return;
    if (med.endDate != null && med.endDate!.isBefore(now)) return;

    for (var i = 0; i < med.schedule.length; i++) {
      final time = med.schedule[i];
      final scheduledDate =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);

      // Si l'heure est déjà passée aujourd'hui, programmer pour demain
      var finalDate = scheduledDate;
      if (scheduledDate.isBefore(now)) {
        finalDate = scheduledDate.add(const Duration(days: 1));
      }

      String description = med.aiRecommendation ??
          'Il est temps de prendre votre traitement : ${med.dosage}';

      final alerte = ModeleAlerte(
        id: 'med_${med.id}_$i',
        titre: 'Rappel : ${med.name}',
        description: description,
        type: TypeAlerte.medicament,
        dateCreation: now,
        statut: StatutAlerte.nouvelle,
        niveauPriorite: med.isCritical ? 95 : 60,
        tags: ['médicament', med.isCritical ? 'critique' : 'normal'],
        idUtilisateur: '1',
      );

      if (med.isCritical) {
        // Pour les médicaments critiques, on programme plusieurs rappels (toutes les 10 min, 3 fois)
        // pour simuler le "tant que pas confirmé"
        for (var j = 0; j < 3; j++) {
          final repeatDate = finalDate.add(Duration(minutes: j * 10));
          _notificationService.programmerNotificationAlerte(
            alerte.copiAvec(
              id: 'med_${med.id}_${i}_rep_$j',
              titre: j == 0 ? alerte.titre : '${alerte.titre} (Rappel $j)',
              severite: NiveauSeverite.critique,
            ),
            repeatDate,
          );
        }
      } else {
        _notificationService.programmerNotificationAlerte(alerte, finalDate);
      }
    }
  }

  /// Met en avant un médicament suite à une analyse IA
  void highlightMedication(String name, String recommendation) {
    bool found = false;
    for (var i = 0; i < _medications.length; i++) {
      if (_medications[i].name.toLowerCase().contains(name.toLowerCase())) {
        _medications[i] = _medications[i].copyWith(
          isHighlighted: true,
          aiRecommendation: recommendation,
        );
        // Reprogrammer les notifications avec la recommandation IA
        _scheduleMedicationNotifications(_medications[i]);
        found = true;
      }
    }
    if (found) notifyListeners();
  }

  /// Efface toutes les mises en avant IA
  void clearHighlights() {
    bool changed = false;
    for (var i = 0; i < _medications.length; i++) {
      if (_medications[i].isHighlighted) {
        _medications[i] = _medications[i].copyWith(
          isHighlighted: false,
          aiRecommendation: null,
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void addMedication(Medication medication) {
    _medications.add(medication);
    _scheduleMedicationNotifications(medication);
    notifyListeners();
  }

  void removeMedication(String id) {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = _medications[index];
      // Annuler les notifications (y compris les répétitions)
      for (var i = 0; i < med.schedule.length; i++) {
        _notificationService
            .annulerNotificationLocale('med_${med.id}_$i'.hashCode);
        for (var j = 0; j < 3; j++) {
          _notificationService
              .annulerNotificationLocale('med_${med.id}_${i}_rep_$j'.hashCode);
        }
      }
      _medications.removeAt(index);
      notifyListeners();
    }
  }

  void toggleTaken(String id) {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = _medications[index];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (med.isTakenToday) {
        med.isTakenToday = false;
        med.history.removeWhere((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);
      } else {
        med.isTakenToday = true;
        med.history.add(today);
        // Annuler les notifications du jour (y compris les répétitions)
        for (var i = 0; i < med.schedule.length; i++) {
          _notificationService
              .annulerNotificationLocale('med_${med.id}_$i'.hashCode);
          for (var j = 0; j < 3; j++) {
            _notificationService.annulerNotificationLocale(
                'med_${med.id}_${i}_rep_$j'.hashCode);
          }
        }
        // Effacer le highlight si présent
        if (med.isHighlighted) {
          _medications[index] = med.copyWith(
            isHighlighted: false,
            aiRecommendation: null,
          );
        }
      }
      notifyListeners();
    }
  }

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

  int getMissedDosesCount(DateTime date) {
    int missed = 0;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    for (var med in _medications) {
      // Vérifier si le traitement était actif à cette date
      if (med.startDate != null && med.startDate!.isAfter(date)) continue;
      if (med.endDate != null && med.endDate!.isBefore(date)) continue;

      if (!isTakenOn(med.id, date)) {
        // Si c'est aujourd'hui, on ne compte comme manqué que si toutes les heures sont passées
        if (isToday) {
          final lastSchedule = med.schedule.last;
          final lastTime = DateTime(now.year, now.month, now.day,
              lastSchedule.hour, lastSchedule.minute);
          if (now.isAfter(lastTime)) {
            missed++;
          }
        } else if (date.isBefore(now)) {
          missed++;
        }
      }
    }
    return missed;
  }

  double get adherenceRate {
    if (_medications.isEmpty) return 1.0;
    final takenCount = _medications.where((m) => m.isTakenToday).length;
    return takenCount / _medications.length;
  }
}
