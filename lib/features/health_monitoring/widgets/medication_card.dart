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
                const SizedBox(height: 12),
                if (medications.isEmpty)
                  const Text('Aucun traitement ajouté.')
                else
                  Column(
                    children: [
                      // Section "Action Requise" pour les highlights IA
                      ...medications.where((m) => m.isHighlighted).map(
                            (med) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome,
                                          color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ACTION REQUISE : ${med.name}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        onPressed: () =>
                                            service.toggleTaken(med.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    med.aiRecommendation ??
                                        'Prenez ce médicament maintenant.',
                                    style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),

                      // Liste standard simplifiée
                      ...medications.map((med) {
                        final isMissed = !med.isTakenToday &&
                            med.schedule.any((t) {
                              final now = DateTime.now();
                              final scheduleTime = DateTime(now.year, now.month,
                                  now.day, t.hour, t.minute);
                              return now.isAfter(scheduleTime);
                            });

                        return ListTile(
                          title: Row(
                            children: [
                              Text(med.name,
                                  style: TextStyle(
                                      fontWeight: med.isHighlighted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: med.isHighlighted
                                          ? Colors.red
                                          : null)),
                              if (med.isCritical)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Icon(Icons.warning,
                                      color: Colors.orange, size: 14),
                                ),
                            ],
                          ),
                          subtitle: Text(
                              '${med.dosage} - ${med.schedule.length}x/jour'),
                          trailing: med.isTakenToday
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : (isMissed
                                  ? const Icon(Icons.error, color: Colors.red)
                                  : const Icon(Icons.circle_outlined,
                                      color: Colors.grey)),
                          onTap: () => service.toggleTaken(med.id),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ],
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
