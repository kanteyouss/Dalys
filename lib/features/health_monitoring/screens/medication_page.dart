import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/medication_service.dart';
import '../../../data/models/medication_model.dart';
import 'package:table_calendar/table_calendar.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    List<TimeOfDay> selectedTimes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un traitement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nom du médicament'),
              ),
              TextField(
                controller: dosageController,
                decoration:
                    const InputDecoration(labelText: 'Dosage (ex: 10mg)'),
              ),
              const SizedBox(height: 16),
              const Text('Heures de prise :',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: selectedTimes
                    .map((time) => Chip(
                          label: Text(time.format(context)),
                          onDeleted: () {
                            setState(() {
                              selectedTimes.remove(time);
                            });
                          },
                        ))
                    .toList(),
              ),
              TextButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      selectedTimes.add(time);
                      // Trier les heures
                      selectedTimes.sort((a, b) =>
                          (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
                    });
                  }
                },
                icon: const Icon(Icons.access_time),
                label: const Text('Ajouter une heure'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    selectedTimes.isNotEmpty) {
                  final med = Medication(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    dosage: dosageController.text,
                    frequencyPerDay: selectedTimes.length,
                    schedule: selectedTimes,
                  );
                  context.read<MedicationService>().addMedication(med);
                  Navigator.pop(context);
                } else if (selectedTimes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Veuillez ajouter au moins une heure')));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Traitements'),
      ),
      body: Consumer<MedicationService>(
        builder: (context, service, child) {
          final medications = service.medications;

          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun traitement enregistré'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMedicationDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un médicament'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  // Vérifier si des médicaments ont été pris ce jour-là
                  final hasTakenMeds =
                      medications.any((med) => service.isTakenOn(med.id, day));
                  return hasTakenMeds ? [true] : [];
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    // Vérifier si pris le jour sélectionné (ou aujourd'hui par défaut)
                    final checkDate = _selectedDay ?? DateTime.now();
                    final isTaken = service.isTakenOn(med.id, checkDate);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTaken ? Colors.green : Colors.teal,
                          child: Icon(
                              isTaken ? Icons.check : Icons.local_pharmacy,
                              color: Colors.white),
                        ),
                        title: Text(med.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${med.dosage} • ${med.frequencyPerDay}x/jour'),
                            if (med.schedule.isNotEmpty)
                              Text(
                                'Horaires : ${med.schedule.map((t) => t.format(context)).join(", ")}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => service.removeMedication(med.id),
                        ),
                        onTap: () {
                          // Permettre de marquer comme pris pour le jour sélectionné
                          // Note: MedicationService.toggleTaken ne gère actuellement que "aujourd'hui"
                          // Pour une vraie gestion historique, il faudrait update toggleTaken pour accepter une date.
                          // Pour l'instant, on désactive l'interaction si ce n'est pas aujourd'hui
                          final now = DateTime.now();
                          if (checkDate.year == now.year &&
                              checkDate.month == now.month &&
                              checkDate.day == now.day) {
                            service.toggleTaken(med.id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Modification impossible pour les dates passées (Simulation)')));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
