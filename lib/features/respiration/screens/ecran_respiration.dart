import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/modele_respiration.dart';
import '../services/service_respiration.dart';
import '../widgets/cercle_respiration.dart';

class EcranRespiration extends StatelessWidget {
  const EcranRespiration({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceRespiration(),
      child: const _EcranRespirationContent(),
    );
  }
}

class _EcranRespirationContent extends StatelessWidget {
  const _EcranRespirationContent();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceRespiration>();
    final techniques = ModeleTechniqueRespiration.techniques;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réhabilitation Respiratoire'),
        backgroundColor: service.estEnCours
            ? service.techniqueActuelle!.couleurTheme.withOpacity(0.8)
            : null,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!service.estEnCours) ...[
              const Icon(Icons.air, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Choisissez une technique',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: techniques.length,
                  itemBuilder: (context, index) {
                    final tech = techniques[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: tech.couleurTheme.withOpacity(0.2),
                          child: Icon(tech.icone, color: tech.couleurTheme),
                        ),
                        title: Text(tech.nom,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(tech.description),
                        onTap: () => context
                            .read<ServiceRespiration>()
                            .demarrerExercice(tech),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Text(
                service.techniqueActuelle!.nom,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Cycle ${service.cycleActuel}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const Spacer(),
              CercleRespiration(
                phase: service.phaseActuelle,
                dureeTotalePhase: service.secondesRestantesPhase,
                couleur: service.techniqueActuelle!.couleurTheme,
              ),
              const SizedBox(height: 48),
              Text(
                '${service.secondesRestantesPhase}s',
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<ServiceRespiration>().arreterExercice(),
                icon: const Icon(Icons.stop),
                label: const Text('ARRÊTER L\'EXERCICE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
