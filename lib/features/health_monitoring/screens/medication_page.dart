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
    DateTime? startDate = DateTime.now();
    DateTime? endDate;
    bool isCritical = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un traitement'),
          content: SingleChildScrollView(
            child: Column(
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
                SwitchListTile(
                  title: const Text('Médicament critique'),
                  subtitle: const Text('Rappels plus fréquents et urgents'),
                  value: isCritical,
                  onChanged: (val) => setState(() => isCritical = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Date de début'),
                  subtitle: Text(startDate == null
                      ? 'Non définie'
                      : '${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setState(() => startDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Date de fin'),
                  subtitle: Text(endDate == null
                      ? 'Traitement continu'
                      : '${endDate!.day}/${endDate!.month}/${endDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) setState(() => endDate = date);
                  },
                ),
                const Divider(),
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
                        selectedTimes.sort((a, b) =>
                            (a.hour * 60 + a.minute) -
                            (b.hour * 60 + b.minute));
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: const Text('Ajouter une heure'),
                ),
              ],
            ),
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
                    startDate: startDate,
                    endDate: endDate,
                    isCritical: isCritical,
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
                  final hasTakenMeds =
                      medications.any((med) => service.isTakenOn(med.id, day));
                  return hasTakenMeds ? [true] : [];
                },
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Section "Action Requise" pour les highlights IA
                    ...medications.where((m) => m.isHighlighted).map(
                          (med) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.red.shade300, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome,
                                        color: Colors.red),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'ACTION MÉDICALE : ${med.name}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          service.toggleTaken(med.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                      child: const Text('CONFIRMER'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  med.aiRecommendation ??
                                      'Prenez ce médicament immédiatement.',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                    const Text(
                      'Vos Traitements',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ...medications.map((med) {
                      final checkDate = _selectedDay ?? DateTime.now();
                      final isTaken = service.isTakenOn(med.id, checkDate);
                      final isMissed =
                          !isTaken && checkDate.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTaken
                                ? Colors.green.shade100
                                : (isMissed
                                    ? Colors.red.shade100
                                    : Colors.teal.shade100),
                            child: Icon(
                              isTaken
                                  ? Icons.check
                                  : (isMissed
                                      ? Icons.priority_high
                                      : Icons.medication),
                              color: isTaken
                                  ? Colors.green
                                  : (isMissed ? Colors.red : Colors.teal),
                            ),
                          ),
                          title: Text(
                            med.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: med.isHighlighted ? Colors.red : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${med.dosage} - ${med.schedule.length}x/jour'),
                              if (med.startDate != null)
                                Text(
                                  'Du ${med.startDate!.day}/${med.startDate!.month} au ${med.endDate?.day}/${med.endDate?.month}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (med.isCritical)
                                const Icon(Icons.warning,
                                    color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              const Icon(Icons.notifications_active,
                                  color: Colors.teal, size: 16),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    service.removeMedication(med.id),
                              ),
                            ],
                          ),
                          onTap: () {
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
                    }).toList(),
                  ],
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
