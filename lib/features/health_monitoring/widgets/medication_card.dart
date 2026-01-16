import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/medication_service.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationService>(
      builder: (context, service, child) {
        final medications = service.medications;
        final adherence = service.adherenceRate;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medication, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Traitements',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/medications'),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_month, size: 16),
                          SizedBox(width: 4),
                          Text('Calendrier'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (medications.isEmpty)
                  const Text('Aucun traitement ajouté.')
                else
                  Column(
                    children: medications.map((med) {
                      return CheckboxListTile(
                        title: Text(med.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${med.dosage} - ${med.schedule.length}x/jour'),
                        value: med.isTakenToday,
                        onChanged: (bool? value) {
                          service.toggleTaken(med.id);
                        },
                        secondary: Icon(
                          med.isTakenToday
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: med.isTakenToday ? Colors.green : Colors.grey,
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: adherence,
                  backgroundColor: Colors.teal.shade100,
                  color: Colors.teal,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Observance du jour : ${(adherence * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
