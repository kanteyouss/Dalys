import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../widgets/health_indicator_card.dart';
import '../widgets/risk_level_indicator.dart';
import '../widgets/health_chart.dart';
import '../widgets/add_measurement_dialog.dart';
import '../../ai_suggestions/widgets/carte_suggestion.dart';
import '../../../data/services/service_ia.dart';
import '../../../data/models/modele_suggestion.dart';
import '../../../data/models/health_data.dart';
import '../../../data/services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../alertes/widgets/emergency_countdown_overlay.dart';
import '../../../core/enums/app_enums.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  List<Suggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthController>().initialize();
      _loadSuggestions();
    });
  }

  Future<void> _loadSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final controller = context.read<HealthController>();
    if (controller.currentHealthData != null) {
      final suggestions =
          await ServiceIA().getSuggestions(controller.currentHealthData!);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    }
  }

  Trend _calculateTrend(List<HealthData> history, double currentValue,
      double Function(HealthData) selector) {
    if (history.length < 2) return Trend.stable;
    final recentHistory = history.take(3).toList();
    if (recentHistory.isEmpty) return Trend.stable;

    double previousAverage = 0;
    for (var data in recentHistory) {
      previousAverage += selector(data);
    }
    previousAverage /= recentHistory.length;

    final diff = currentValue - previousAverage;
    final threshold = previousAverage * 0.02;

    if (diff > threshold) return Trend.up;
    if (diff < -threshold) return Trend.down;
    return Trend.stable;
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
          Consumer<HealthController>(
            builder: (context, controller, _) {
              return Switch(
                value: controller.isSimulationMode,
                onChanged: (value) => controller.toggleSimulationMode(value),
                activeColor: Colors.white,
                activeTrackColor: Colors.greenAccent,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Erreur',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(controller.error!, textAlign: TextAlign.center),
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
            return const Center(child: Text('Aucune donnée disponible'));
          }

          final history = controller.historicalData.reversed.toList();
          final spo2Trend = _calculateTrend(
              history, currentData.spo2.toDouble(), (d) => d.spo2.toDouble());
          final breathingTrend = _calculateTrend(
              history,
              currentData.breathingRate.toDouble(),
              (d) => d.breathingRate.toDouble());
          final pefTrend =
              _calculateTrend(history, currentData.pef, (d) => d.pef);

          final isHighRisk = currentData.riskLevel == RiskLevel.high;
          final backgroundColor = isHighRisk
              ? Colors.red.shade50.withOpacity(0.5)
              : Colors.transparent;

          return RefreshIndicator(
            onRefresh: () async {
              await controller.refreshData();
              await _loadSuggestions();
            },
            child: Container(
              color: backgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isHighRisk) _buildCrisisBanner(),
                    RiskLevelIndicator(riskLevel: currentData.riskLevel),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Paramètres Vitaux',
                        onInfo: () => _showGlobalInfo(context)),
                    const SizedBox(height: 16),
                    _buildSOSButton(context),
                    Row(
                      children: [
                        Expanded(
                          child: HealthIndicatorCard(
                            title: 'SpO₂',
                            value: '${currentData.spo2}%',
                            icon: Icons.favorite,
                            color: currentData.isSpo2Normal
                                ? Colors.green
                                : Colors.red,
                            normalRange: '95-100%',
                            trend: spo2Trend,
                            onTap: () => _showParameterDetails(
                                context, 'SpO₂', currentData.spo2.toString()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HealthIndicatorCard(
                            title: 'Respiration',
                            value: '${currentData.breathingRate} bpm',
                            icon: Icons.air,
                            color: currentData.isBreathingRateNormal
                                ? Colors.green
                                : Colors.red,
                            normalRange: '12-20 bpm',
                            trend: breathingTrend,
                            onTap: () => _showParameterDetails(
                                context,
                                'Respiration',
                                '${currentData.breathingRate} bpm'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    HealthIndicatorCard(
                      title: 'Débit de pointe (PEF)',
                      value: '${currentData.pef.toInt()} L/min',
                      icon: Icons.timeline,
                      color:
                          currentData.isPefNormal ? Colors.green : Colors.red,
                      normalRange: '350-500 L/min',
                      trend: pefTrend,
                      onTap: () => _showParameterDetails(
                          context, 'PEF', '${currentData.pef.toInt()} L/min'),
                    ),
                    const SizedBox(height: 12),
                    if (currentData.temperature != null ||
                        currentData.humidity != null)
                      Row(
                        children: [
                          if (currentData.temperature != null)
                            Expanded(
                              child: HealthIndicatorCard(
                                title: 'Température',
                                value:
                                    '${currentData.temperature!.toStringAsFixed(1)}°C',
                                icon: Icons.thermostat,
                                color: (currentData.temperature! >= 36.0 &&
                                        currentData.temperature! <= 37.8)
                                    ? Colors.green
                                    : Colors.orange,
                                normalRange: '36.5-37.5°C',
                                onTap: () => _showParameterDetails(
                                    context,
                                    'Température',
                                    '${currentData.temperature!.toStringAsFixed(1)}°C'),
                              ),
                            ),
                          if (currentData.temperature != null &&
                              currentData.humidity != null)
                            const SizedBox(width: 12),
                          if (currentData.humidity != null)
                            Expanded(
                              child: HealthIndicatorCard(
                                title: 'Humidité',
                                value: '${currentData.humidity!.toInt()}%',
                                icon: Icons.water_drop,
                                color: Colors.blue,
                                normalRange: '40-60%',
                                onTap: () => _showParameterDetails(
                                    context,
                                    'Humidité',
                                    '${currentData.humidity!.toInt()}%'),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Évolution (7 jours)'),
                    const SizedBox(height: 16),
                    HealthChart(
                        data: controller.historicalData,
                        title: 'SpO₂',
                        parameter: 'spo2',
                        color: Colors.red.shade400,
                        minY: 85,
                        maxY: 100),
                    const SizedBox(height: 16),
                    HealthChart(
                        data: controller.historicalData,
                        title: 'Respiration',
                        parameter: 'breathingRate',
                        color: Colors.blue.shade400,
                        minY: 10,
                        maxY: 30),
                    const SizedBox(height: 16),
                    HealthChart(
                        data: controller.historicalData,
                        title: 'PEF',
                        parameter: 'pef',
                        color: Colors.green.shade400,
                        minY: 200,
                        maxY: 600),
                    const SizedBox(height: 24),
                    if (currentData.symptoms.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Symptômes signalés'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentData.symptoms
                            .map((symptom) => Chip(
                                  label: Text(symptom),
                                  backgroundColor: Colors.orange.shade100,
                                  avatar: Icon(Icons.warning_amber,
                                      size: 18, color: Colors.orange.shade600),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_suggestions.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Conseils IA',
                          onAction: () =>
                              Navigator.pushNamed(context, '/suggestions'),
                          actionLabel: 'Voir tout'),
                      const SizedBox(height: 8),
                      ..._suggestions
                          .take(2)
                          .map((suggestion) => CarteSuggestion(
                                suggestion: suggestion,
                                onTap: () => Navigator.pushNamed(
                                    context, '/suggestions'),
                              )),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionHeader(context, 'Actions rapides'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pushNamed(context, '/chatbot');
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Signaler symptômes'),
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pushNamed(context, '/suggestions');
                            },
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text('Conseils IA'),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => const AddMeasurementDialog());
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Nouvelle mesure'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildCrisisBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ÉTAT CRITIQUE DÉTECTÉ : Restez calme et suivez les instructions.',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onInfo, VoidCallback? onAction, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
          ),
        ),
        if (onInfo != null)
          IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: onInfo),
        if (onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel ?? 'Voir')),
      ],
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          final user = AuthService().currentUser;
          if (user != null) {
            HapticFeedback.heavyImpact();
            EmergencyCountdownOverlay.show(
                context, user, 'Déclenchement Manuel (SOS)');
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DÉCLENCHER SOS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1)),
                    Text('Alerte immédiate aux proches',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlobalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suivi Respiratoire'),
        content: const Text(
            'Ces indicateurs permettent de suivre votre santé pulmonaire au quotidien. En cas de valeurs anormales (en rouge), restez calme et suivez les conseils de l\'IA ou déclenchez une alerte si nécessaire.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'))
        ],
      ),
    );
  }

  void _showParameterDetails(
      BuildContext context, String parameter, String value) {
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
            Text(_getParameterDescription(parameter),
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'))
        ],
      ),
    );
  }

  String _getParameterDescription(String parameter) {
    switch (parameter) {
      case 'SpO₂':
        return 'La saturation en oxygène mesure le pourcentage d\'oxygène dans le sang. Une valeur normale se situe entre 95% et 100%.';
      case 'Respiration':
        return 'La fréquence respiratoire indique le nombre de respirations par minute. La normale pour un adulte est entre 12 et 20 bpm.';
      case 'PEF':
        return 'Le débit expiratoire de pointe mesure la vitesse maximale d\'expiration. Il aide à évaluer la fonction pulmonaire.';
      case 'Température':
        return 'La normale se situe entre 36.5°C et 37.5°C.';
      case 'Humidité':
        return 'Un taux entre 40% et 60% est idéal pour le confort respiratoire.';
      default:
        return 'Paramètre de santé important.';
    }
  }
}
