import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../widgets/health_indicator_card.dart';
import '../widgets/status_hero_section.dart';
import '../widgets/medication_card.dart';
import '../widgets/comprehensive_forecast_card.dart';
import '../widgets/multi_horizon_alerts_widget.dart';
import '../../ai_suggestions/widgets/carte_suggestion.dart';
import '../../../data/services/service_ia_enhanced.dart';
import '../../../data/models/modele_suggestion.dart';
import '../../../data/models/health_data.dart';
import '../../../data/models/fragility_models.dart';
import '../../../data/models/patient_risk_profile.dart';
import '../../../data/models/comprehensive_forecast_models.dart';
import '../../../data/models/multi_horizon_alerts_models.dart';
import '../../../data/services/fragility_score_service.dart';
import '../../../data/services/health_forecast_service.dart';
import '../../../data/services/database_service.dart';
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
  bool _isLoadingScore = false;
  final ExpansionTileController _expansionController =
      ExpansionTileController();

  // 🔮 NOUVEAUX ÉTATS POUR LES PRÉVISIONS AVANCÉES
  ComprehensiveHealthForecast? _comprehensiveForecast;
  bool _isLoadingForecast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<HealthController>();
      controller.initialize();
      controller.addListener(_onHealthDataChanged);
      _loadSuggestions();
    });
  }

  @override
  void dispose() {
    // Retirer le listener quand le widget est détruit
    try {
      context.read<HealthController>().removeListener(_onHealthDataChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Appelé automatiquement quand les données de santé changent
  void _onHealthDataChanged() {
    if (!mounted) return;
    // Recharger le score de fragilité à chaque nouvelle donnée
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (_isLoadingScore) return; // Éviter les appels multiples simultanés

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final controller = context.read<HealthController>();
    if (controller.currentHealthData != null &&
        controller.currentHealthData!.userId != null) {
      final serviceIA = ServiceIAEnhanced();
      final suggestions = await serviceIA.getPredictiveSuggestions(
        controller.currentHealthData!,
        userId: controller.currentHealthData!.userId!,
      );

      // Récupérer le score de fragilité via le service
      await _loadFragilityScore(controller.currentHealthData!.userId!);

      // 🔮 CHARGER LES PRÉVISIONS COMPLÈTES
      final forecast = await _loadComprehensiveForecast(
          controller.currentHealthData!.userId!);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _comprehensiveForecast = forecast;
          _isLoadingScore = false;
          _isLoadingForecast = false;
        });

        // Auto-expansion si risque élevé ou nouveaux conseils
        final controller = context.read<HealthController>();
        if (controller.currentHealthData?.riskLevel == RiskLevel.high ||
            suggestions.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_expansionController.isExpanded) {
              _expansionController.expand();
            }
          });
        }
      }
    }
  }

  Future<FragilityScore?> _loadFragilityScore(int userId) async {
    _isLoadingScore = true;
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      // Récupérer TOUTES les données de l'utilisateur (pas seulement 14 jours)
      // Pour permettre l'affichage même avec peu de données
      final results = await db.query(
        'health_data',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: 50, // Plus de données pour meilleure analyse
      );

      if (results.isEmpty) {
        debugPrint('⚠️ Aucune donnée en DB pour userId=$userId');
        return null;
      }

      debugPrint('✅ ${results.length} données trouvées pour userId=$userId');

      // Convertir et trier chronologiquement
      final history = results.map((row) {
        // Adaptation des champs DB vers le modèle
        return HealthData.fromJson({
          'user_id': row['user_id'],
          'date': row['date'],
          'spo2': row['spo2'],
          'breathing_rate': row['breathing_rate'],
          'pef': row['pef'],
          'temperature': row['temperature'],
          'humidity': row['humidity'],
          'env_temperature': row['env_temperature'],
          'symptoms': (row['symptoms'] as String?)?.isEmpty ?? true
              ? <String>[]
              : (row['symptoms'] as String).split(','),
          'risk_level': row['risk_level'],
        });
      }).toList();

      // Trier chronologiquement (plus ancien en premier)
      history.sort((a, b) => a.date.compareTo(b.date));

      final profile = PatientRiskProfile.createDefault(userId);
      final fragilityService = FragilityScoreService();

      return await fragilityService.calculateCurrentFragility(history, profile);
    } catch (e) {
      debugPrint('❌ Erreur chargement score fragilité: $e');
      return null;
    } finally {
      _isLoadingScore = false;
    }
  }

  /// 🔮 CHARGE LES PRÉVISIONS COMPLÈTES EXPLOITANT TOUT L'HISTORIQUE
  Future<ComprehensiveHealthForecast?> _loadComprehensiveForecast(
      int userId) async {
    if (_isLoadingForecast) return null;

    _isLoadingForecast = true;
    try {
      final healthForecastService = HealthForecastService();
      final forecast =
          await healthForecastService.generateComprehensiveForecast(userId);

      debugPrint(
          '✅ Prévision générée: ${forecast.dataPoints} points de données sur ${forecast.timeSpan.inDays}j');
      return forecast;
    } catch (e) {
      debugPrint('❌ Erreur génération prévisions: $e');
      return null;
    } finally {
      _isLoadingForecast = false;
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
          _calculateTrend(history, currentData.pef, (d) => d.pef);

          final isHighRisk = currentData.riskLevel == RiskLevel.high;
          final backgroundColor = isHighRisk
              ? Colors.red.shade50.withValues(alpha: 0.5)
              : Colors.transparent;

          return DefaultTabController(
            length: 3,
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  StatusHeroSection(
                    riskLevel: currentData.riskLevel,
                    action: _buildSOSButton(context, isHighRisk, compact: true),
                  ),

                  // TabBar pour la navigation
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      tabs: [
                        const Tab(
                            text: 'Aujourd\'hui', icon: Icon(Icons.today)),
                        const Tab(
                            text: 'Prévisions', icon: Icon(Icons.psychology)),
                        Tab(
                          child: Badge(
                            isLabelVisible: _suggestions.isNotEmpty,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.build),
                                SizedBox(width: 8),
                                Text('Outils'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: Theme.of(context).primaryColor,
                      dividerColor: Colors.transparent,
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // ONGLET 1 : AUJOURD'HUI
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                context,
                                'Paramètres Vitaux',
                                onInfo: () => _showGlobalInfo(context),
                              ),
                              const SizedBox(height: 12),
                              _buildVitalsGrid(context, currentData, spo2Trend,
                                  breathingTrend),
                              const SizedBox(height: 12),
                              _buildDataStatusIndicator(context, controller),
                              const SizedBox(height: 12),
                              const MedicationCard(),
                              const SizedBox(height: 24),
                              _buildContextSection(context, currentData),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),

                        // ONGLET 2 : PRÉVISIONS
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                context,
                                '🔮 Intelligence Prédictive',
                                onInfo: () =>
                                    _showAdvancedForecastInfo(context),
                              ),
                              const SizedBox(height: 12),
                              if (_comprehensiveForecast != null) ...[
                                ComprehensiveForecastCard(
                                  forecast: _comprehensiveForecast!,
                                  onTap: () => _showForecastDetails(
                                      context, _comprehensiveForecast!),
                                ),
                                const SizedBox(height: 16),
                                if (_comprehensiveForecast!
                                    .multiHorizonAlerts.hasAlerts)
                                  MultiHorizonAlertsWidget(
                                    alerts: _comprehensiveForecast!
                                        .multiHorizonAlerts,
                                    onViewDetails: () => _showAlertsDetails(
                                        context,
                                        _comprehensiveForecast!
                                            .multiHorizonAlerts),
                                  ),
                              ] else
                                _buildForecastLoadingCard(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),

                        // ONGLET 3 : OUTILS
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataModeSection(context, controller),
                              const SizedBox(height: 24),
                              _buildTrainingSection(context),
                              const SizedBox(height: 24),
                              _buildQuickActions(context),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataStatusIndicator(
      BuildContext context, HealthController controller) {
    final isSim = controller.isSimulationMode;
    final isConnected = controller.isESP32Connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSim
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSim
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSim ? Icons.science : Icons.bluetooth_connected,
            size: 16,
            color: isSim ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isSim ? 'Mode Simulation Actif' : 'Connecté à l\'ESP32',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSim ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          ),
          if (!isSim && !isConnected) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataModeSection(
      BuildContext context, HealthController controller) {
    final theme = Theme.of(context);
    final isSim = controller.isSimulationMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Source des Données'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSim
                            ? Colors.orange.withValues(alpha: 0.1)
                            : theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSim ? Icons.science : Icons.settings_input_antenna,
                        color: isSim ? Colors.orange : theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSim ? 'Mode Simulation' : 'Mode Capteur Réel',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            isSim
                                ? 'Données fictives pour test'
                                : 'Données directes de l\'ESP32',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: !isSim,
                      onChanged: (value) async {
                        await controller.toggleSimulationMode(!value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value
                                  ? 'Tentative de connexion à l\'ESP32...'
                                  : 'Mode Simulation activé'),
                              backgroundColor:
                                  value ? theme.primaryColor : Colors.orange,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      activeThumbColor: theme.primaryColor,
                    ),
                  ],
                ),
                if (!isSim && !controller.isESP32Connected) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recherche de l\'ESP32...',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.autoDetectESP32(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onInfo, VoidCallback? onAction, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
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

  Widget _buildContextSection(BuildContext context, HealthData currentData) {
    final isCritical = currentData.riskLevel == RiskLevel.high ||
        _suggestions.any((s) => s.type == TypeSuggestion.alert);

    return Card(
      elevation: isCritical ? 4 : 2,
      shadowColor: isCritical ? Colors.red.withValues(alpha: 0.2) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCritical
            ? BorderSide(color: Colors.red.shade200, width: 1)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        controller: _expansionController,
        leading: Icon(
            isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isCritical ? Colors.red.shade600 : Colors.blue.shade600),
        title: Text(
          'Contexte & Conseils',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCritical ? Colors.red.shade800 : Colors.black87,
          ),
        ),
        subtitle: Text(
          _suggestions.isNotEmpty
              ? '${_suggestions.length} conseil(s) disponible(s)'
              : 'Tout est normal',
          style: TextStyle(
            fontSize: 13,
            color: isCritical ? Colors.red.shade600 : Colors.grey.shade600,
            fontWeight: isCritical ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentData.symptoms.isNotEmpty) ...[
                  const Text(
                    'Symptômes signalés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildSymptomChips(currentData.symptoms),
                  const SizedBox(height: 16),
                ],
                if (currentData.temperature != null ||
                    currentData.humidity != null) ...[
                  _buildEnvironmentalSection(context, currentData),
                  const SizedBox(height: 16),
                ],
                if (_suggestions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Conseils personnalisés',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/suggestions'),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._suggestions.take(2).map((suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CarteSuggestion(
                          suggestion: suggestion,
                          onTap: () =>
                              Navigator.pushNamed(context, '/suggestions'),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, bool isHighRisk,
      {bool compact = false}) {
    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final user = AuthService().currentUser;
            if (user != null) {
              HapticFeedback.heavyImpact();
              EmergencyCountdownOverlay.show(
                  context, user, 'Déclenchement Manuel (SOS)');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isHighRisk ? 24 : 0),
      child: InkWell(
        onTap: () {
          final user = AuthService().currentUser;
          if (user != null) {
            HapticFeedback.heavyImpact();
            EmergencyCountdownOverlay.show(
                context, user, 'Déclenchement Manuel (SOS)');
          }
        },
        borderRadius: BorderRadius.circular(isHighRisk ? 24 : 16),
        child: Container(
          padding: EdgeInsets.all(isHighRisk ? 28 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHighRisk
                  ? [Colors.red.shade800, Colors.red.shade600]
                  : [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isHighRisk ? 24 : 16),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.emergency,
                  color: Colors.white, size: isHighRisk ? 56 : 32),
              SizedBox(width: isHighRisk ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHighRisk ? 'SOS URGENCE' : 'Aide d\'urgence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isHighRisk ? 26 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isHighRisk) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez pour déclencher le protocole',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                    ] else
                      Text(
                        'Alerte immédiate aux proches',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isHighRisk)
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsGrid(BuildContext context, HealthData currentData,
      Trend spo2Trend, Trend breathingTrend) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HealthIndicatorCard(
                title: 'Oxygène',
                value: '${currentData.spo2}%',
                icon: Icons.favorite,
                color: currentData.isSpo2Normal ? Colors.green : Colors.red,
                normalRange: '95-100%',
                trend: spo2Trend,
                onTap: () => _showParameterDetails(
                    context, 'Oxygène', currentData.spo2.toString()),
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
                    context, 'Respiration', '${currentData.breathingRate} bpm'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HealthIndicatorCard(
                title: 'Pouls',
                value: '${currentData.heartRate ?? "--"} bpm',
                icon: Icons.favorite,
                color:
                    currentData.isHeartRateNormal ? Colors.green : Colors.red,
                normalRange: '60-100 bpm',
                onTap: () => _showParameterDetails(
                    context, 'Pouls', '${currentData.heartRate ?? "--"} bpm'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HealthIndicatorCard(
                title: 'Souffle (PEF)',
                value: '${currentData.pef.toInt()} L/min',
                icon: Icons.speed,
                color: currentData.isPefNormal ? Colors.green : Colors.red,
                normalRange: '> 350 L/min',
                onTap: () => _showParameterDetails(
                    context, 'Souffle', '${currentData.pef.toInt()} L/min'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentalSection(
      BuildContext context, HealthData currentData) {
    if (currentData.temperature == null && currentData.humidity == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.wb_cloudy_outlined, color: Colors.blueGrey),
            const SizedBox(width: 16),
            const Text(
              'Environnement',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (currentData.temperature != null) ...[
              const Icon(Icons.thermostat, size: 16, color: Colors.orange),
              Text(' ${currentData.temperature!.toStringAsFixed(1)}°C'),
              const SizedBox(width: 16),
            ],
            if (currentData.humidity != null) ...[
              const Icon(Icons.water_drop, size: 16, color: Colors.blue),
              Text(' ${currentData.humidity!.toInt()}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomChips(List<String> symptoms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms
          .map((symptom) => Chip(
                label: Text(symptom, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
                avatar: Icon(Icons.warning_amber,
                    size: 14, color: Colors.orange.shade600),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ))
          .toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Badge(
                isLabelVisible: _suggestions.isNotEmpty,
                label: Text(_suggestions.length.toString()),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    context,
                    'Conseils',
                    Icons.lightbulb_outline,
                    () => Navigator.pushNamed(context, '/suggestions'),
                    isPrimary: false,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context,
            'Partager mes données (PDF)',
            Icons.share,
            () => Navigator.pushNamed(context, '/centre-partage'),
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Entraînement & Réhabilitation'),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shadowColor: Colors.blue.withValues(alpha: 0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/respiration'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa, color: Colors.blue, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respiration Guidée',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cohérence cardiaque et exercices pour renforcer votre souffle.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap,
      {required bool isPrimary}) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? Theme.of(context).primaryColor : Colors.white,
        foregroundColor:
            isPrimary ? Colors.white : Theme.of(context).primaryColor,
        elevation: isPrimary ? 2 : 0,
        side: isPrimary
            ? null
            : BorderSide(color: Theme.of(context).primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPreventionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🔮 Prévention Intelligente'),
          ],
        ),
        content: const Text(
          'Votre score de fragilité (0-100) prédit les risques à venir.\n\n'
          '✅ 0-30 : Excellent, continuez\n'
          '⚠️ 30-70 : Vigilance, suivez les conseils\n'
          '🚨 70-100 : Action rapide nécessaire\n\n'
          'Agissez AVANT que les symptômes n\'apparaissent !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
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
      case 'Oxygène':
        return 'La saturation en oxygène mesure le pourcentage d\'oxygène dans le sang. Une valeur normale se situe entre 95% et 100%.';
      case 'Respiration':
        return 'La fréquence respiratoire indique le nombre de respirations par minute. La normale pour un adulte est entre 12 et 20 bpm.';
      case 'Souffle':
        return 'Le débit de pointe (PEF) mesure la vitesse maximale d\'expiration. Il aide à évaluer la fonction pulmonaire.';
      case 'Température':
        return 'La normale se situe entre 36.5°C et 37.5°C.';
      case 'Humidité':
        return 'Un taux entre 40% et 60% est idéal pour le confort respiratoire.';
      case 'Pouls':
        return 'La fréquence cardiaque (pouls) mesure le nombre de battements du cœur par minute. La normale au repos se situe entre 60 et 100 bpm.';
      default:
        return 'Paramètre de santé important.';
    }
  }

  // 🔮 MÉTHODES POUR LES NOUVELLES FONCTIONNALITÉS AVANCÉES

  Widget _buildForecastLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingForecast
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.blue.shade600),
                          ),
                        )
                      : Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Prévisions IA Avancées',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Text(
                        _isLoadingForecast
                            ? 'Analyse de vos données en cours...'
                            : 'Génération des insights prédictifs',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoadingForecast) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAdvancedForecastInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('🔮 Intelligence Prédictive Avancée'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Notre nouveau système exploite TOUTES vos données historiques pour:'),
              SizedBox(height: 12),
              Text('🎯 Prédictions multi-horizon: 6h, 24h, 7 jours'),
              SizedBox(height: 8),
              Text(
                  '📊 Analyse de tendances long-terme et patterns saisonniers'),
              SizedBox(height: 8),
              Text('⚠️ Alertes préventives intelligentes'),
              SizedBox(height: 8),
              Text('💡 Recommandations stratégiques personnalisées'),
              SizedBox(height: 12),
              Text(
                  'Plus vous utilisez l\'app, plus les prédictions deviennent précises!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showForecastDetails(
      BuildContext context, ComprehensiveHealthForecast forecast) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analyse IA Détaillée',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. RÉSUMÉ HAUTE-IMPACT
                      _buildDetailSectionTitle(
                          context, 'Résumé Décisionnel', Icons.psychology),
                      const SizedBox(height: 12),
                      _buildImpactRow(Icons.flash_on, 'Déclencheur',
                          forecast.primaryTrigger, Colors.orange),
                      if (forecast.actionWindow != null)
                        _buildImpactRow(
                            Icons.timer,
                            'Fenêtre d\'action',
                            'Environ ${forecast.actionWindow!.inHours} heures',
                            Colors.red),
                      _buildImpactRow(Icons.person_search, 'Norme Personnelle',
                          forecast.personalNormComparison, Colors.blue),

                      const SizedBox(height: 24),

                      // 2. FIABILITÉ
                      _buildDetailSectionTitle(context,
                          'Fiabilité de la Prévision', Icons.verified_user),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    forecast.confidenceReason,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analyse basée sur ${forecast.dataPoints} points de données sur les ${forecast.timeSpan.inDays} derniers jours.',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. INSIGHTS & RECOMMANDATIONS
                      _buildDetailSectionTitle(
                          context, 'Insights & Actions', Icons.lightbulb),
                      const SizedBox(height: 12),
                      Text(forecast.executiveSummary,
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      ...forecast.personalizedInsights.significantInsights.map(
                        (insight) => _buildInsightDetailCard(insight),
                      ),

                      const SizedBox(height: 24),

                      // 4. RECOMMANDATIONS CLÉS
                      _buildDetailSectionTitle(context, 'Conseils Stratégiques',
                          Icons.assignment_turned_in),
                      const SizedBox(height: 12),
                      ...forecast.keyRecommendations.map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 18, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rec)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightDetailCard(HealthInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(insight.description,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
            if (insight.actionable && insight.action != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.action!,
                        style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAlertsDetails(BuildContext context, MultiHorizonAlerts alerts) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Toutes les Alertes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: MultiHorizonAlertsWidget(alerts: alerts),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
