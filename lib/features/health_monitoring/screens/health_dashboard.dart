import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../widgets/health_indicator_card.dart';
import '../widgets/risk_level_indicator.dart';
import '../widgets/health_chart.dart';
import '../widgets/add_measurement_dialog.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Santé 4.0 - Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/alerts');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer<HealthController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données de santé...'),
                ],
              ),
            );
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final currentData = controller.currentHealthData;
          if (currentData == null) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicateur de risque global
                  RiskLevelIndicator(
                    riskLevel: currentData.riskLevel,
                  ),
                  const SizedBox(height: 24),

                  // Section Paramètres Vitaux
                  Text(
                    'Paramètres Vitaux',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cartes des indicateurs vitaux
                  Row(
                    children: [
                      Expanded(
                        child: HealthIndicatorCard(
                          title: 'SpO₂',
                          value: '${currentData.spo2}%',
                          icon: Icons.favorite,
                          color: currentData.isSpo2Normal ? Colors.green : Colors.red,
                          normalRange: '95-100%',
                          onTap: () => _showParameterDetails(context, 'SpO₂', currentData.spo2.toString()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HealthIndicatorCard(
                          title: 'Respiration',
                          value: '${currentData.breathingRate} bpm',
                          icon: Icons.air,
                          color: currentData.isBreathingRateNormal ? Colors.green : Colors.red,
                          normalRange: '12-20 bpm',
                          onTap: () => _showParameterDetails(context, 'Respiration', '${currentData.breathingRate} bpm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  HealthIndicatorCard(
                    title: 'Débit de pointe (PEF)',
                    value: '${currentData.pef.toInt()} L/min',
                    icon: Icons.timeline,
                    color: currentData.isPefNormal ? Colors.green : Colors.red,
                    normalRange: '350-500 L/min',
                    onTap: () => _showParameterDetails(context, 'PEF', '${currentData.pef.toInt()} L/min'),
                  ),

                  const SizedBox(height: 24),

                  // Section Évolution
                  Text(
                    'Évolution (7 derniers jours)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Graphiques d'évolution des paramètres vitaux
                  HealthChart(
                    data: controller.historicalData,
                    title: 'Saturation en oxygène (SpO₂)',
                    parameter: 'spo2',
                    color: Colors.red.shade400,
                    minY: 85,
                    maxY: 100,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  HealthChart(
                    data: controller.historicalData,
                    title: 'Fréquence respiratoire',
                    parameter: 'breathingRate',
                    color: Colors.blue.shade400,
                    minY: 10,
                    maxY: 30,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  HealthChart(
                    data: controller.historicalData,
                    title: 'Débit de pointe (PEF)',
                    parameter: 'pef',
                    color: Colors.green.shade400,
                    minY: 200,
                    maxY: 600,
                  ),

                  const SizedBox(height: 16),

                  // Statistiques rapides
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistiques (7 jours)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'SpO₂ moyen',
                                  '${controller.averageSpo2.toStringAsFixed(1)}%',
                                  Icons.favorite,
                                  Colors.red.shade400,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Respiration moy.',
                                  '${controller.averageBreathingRate.toStringAsFixed(1)} bpm',
                                  Icons.air,
                                  Colors.blue.shade400,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'PEF moyen',
                                  '${controller.averagePef.toStringAsFixed(0)} L/min',
                                  Icons.timeline,
                                  Colors.green.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Symptômes actuels
                  if (currentData.symptoms.isNotEmpty) ...[
                    Text(
                      'Symptômes signalés',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentData.symptoms.map((symptom) {
                        return Chip(
                          label: Text(symptom),
                          backgroundColor: Colors.orange.shade100,
                          side: BorderSide(color: Colors.orange.shade300),
                          avatar: Icon(
                            Icons.warning_amber,
                            size: 18,
                            color: Colors.orange.shade600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions rapides
                  Text(
                    'Actions rapides',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                          icon: const Icon(Icons.chat),
                          label: const Text('Signaler symptômes'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/suggestions'),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Conseils IA'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 100), // Espace pour le FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddMeasurementDialog(),
          );
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Nouvelle mesure'),
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Ajouter une nouvelle mesure de santé',
        heroTag: 'add_measurement_fab',
      ),
    );
  }



  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showParameterDetails(BuildContext context, String parameter, String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - $parameter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valeur actuelle: $value'),
            const SizedBox(height: 16),
            Text(
              _getParameterDescription(parameter),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getParameterDescription(String parameter) {
    switch (parameter) {
      case 'SpO₂':
        return 'La saturation en oxygène mesure le pourcentage d\'oxygène dans le sang. Une valeur normale se situe entre 95% et 100%.';
      case 'Respiration':
        return 'La fréquence respiratoire indique le nombre de respirations par minute. La normale pour un adulte est entre 12 et 20 respirations par minute.';
      case 'PEF':
        return 'Le débit expiratoire de pointe mesure la vitesse maximale d\'expiration. Il aide à évaluer la fonction pulmonaire.';
      default:
        return 'Paramètre de santé important pour le suivi respiratoire.';
    }
  }
}
