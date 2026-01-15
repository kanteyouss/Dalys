import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../widgets/health_chart.dart';

class HealthHistoryPage extends StatelessWidget {
  const HealthHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique & Évolution'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Navigator.pushNamed(context, '/centre-partage'),
            tooltip: 'Partager le rapport',
          ),
        ],
      ),
      body: Consumer<HealthController>(
        builder: (context, controller, child) {
          if (controller.historicalData.isEmpty) {
            return const Center(
              child: Text('Aucun historique disponible.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Saturation en oxygène (SpO₂)'),
                const SizedBox(height: 16),
                HealthChart(
                  data: controller.historicalData,
                  title: 'SpO₂',
                  parameter: 'spo2',
                  color: Colors.red.shade400,
                  minY: 85,
                  maxY: 100,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Fréquence respiratoire'),
                const SizedBox(height: 16),
                HealthChart(
                  data: controller.historicalData,
                  title: 'Respiration',
                  parameter: 'breathingRate',
                  color: Colors.blue.shade400,
                  minY: 10,
                  maxY: 30,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Débit de pointe (PEF)'),
                const SizedBox(height: 16),
                HealthChart(
                  data: controller.historicalData,
                  title: 'PEF',
                  parameter: 'pef',
                  color: Colors.green.shade400,
                  minY: 200,
                  maxY: 600,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
