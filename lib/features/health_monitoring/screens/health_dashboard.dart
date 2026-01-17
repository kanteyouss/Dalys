import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../widgets/health_indicator_card.dart';
import '../widgets/status_hero_section.dart';
import '../widgets/medication_card.dart';
import '../widgets/predictive_health_card.dart';
import '../../ai_suggestions/widgets/carte_suggestion.dart';
import '../../../data/services/service_ia_enhanced.dart';
import '../../../data/models/modele_suggestion.dart';
import '../../../data/models/health_data.dart';
import '../../../data/models/fragility_models.dart';
import '../../../data/models/patient_risk_profile.dart';
import '../../../data/services/fragility_score_service.dart';
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
  FragilityScore? _fragilityScore;
  bool _isLoadingScore = false;

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
    if (controller.currentHealthData != null && controller.currentHealthData!.userId != null) {
      final serviceIA = ServiceIAEnhanced();
      final suggestions = await serviceIA.getPredictiveSuggestions(
        controller.currentHealthData!,
        userId: controller.currentHealthData!.userId!,
      );
      
      // Récupérer le score de fragilité via le service
      final score = await _loadFragilityScore(controller.currentHealthData!.userId!);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _fragilityScore = score;
          _isLoadingScore = false;
        });
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
        limit: 50,  // Plus de données pour meilleure analyse
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
                    StatusHeroSection(riskLevel: currentData.riskLevel),
                    const SizedBox(height: 24),

                    // 🔮 PRÉVENTION PRÉDICTIVE - TOUJOURS VISIBLE
                    _buildSectionHeader(
                      context,
                      '🔮 Prévention Intelligente',
                      onInfo: () => _showPreventionInfo(context),
                    ),
                    const SizedBox(height: 12),
                    
                    // Afficher la carte si score disponible, sinon bouton d'accès
                    if (_fragilityScore != null) ... [
                      PredictiveHealthCard(
                        score: _fragilityScore,
                        onTap: () {
                          final user = AuthService().currentUser;
                          if (user != null) {
                            Navigator.pushNamed(
                              context,
                              '/fragility-score',
                              arguments: user.id,
                            );
                          }
                        },
                      ),
                    ] else ... [
                      // Carte placeholder quand pas de score
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () {
                            final user = AuthService().currentUser;
                            if (user != null) {
                              Navigator.pushNamed(
                                context,
                                '/fragility-score',
                                arguments: user.id,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Veuillez vous connecter')),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Analyse Prédictive',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      _isLoadingScore ? Icons.hourglass_empty : Icons.info_outline,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _isLoadingScore 
                                          ? 'Calcul en cours...'
                                          : 'Appuyez pour voir votre score de fragilité',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'userId: ${currentData.userId ?? "non défini"} | Données: ${controller.historicalData.length}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Section: Paramètres Vitaux
                    _buildSectionHeader(
                      context,
                      'Paramètres Vitaux',
                      onInfo: () => _showGlobalInfo(context),
                    ),
                    const SizedBox(height: 16),
                    if (isHighRisk) ... [
                      _buildSOSButton(context, isHighRisk),
                    ],

                    // Vitals Grid
                    _buildVitalsGrid(
                        context, currentData, spo2Trend, breathingTrend),
                    const SizedBox(height: 12),
                    HealthIndicatorCard(
                      title: 'Souffle',
                      value: '${currentData.pef.toInt()} L/min',
                      icon: Icons.timeline,
                      color:
                          currentData.isPefNormal ? Colors.green : Colors.red,
                      normalRange: '350-500 L/min',
                      trend: pefTrend,
                      onTap: () => _showParameterDetails(context, 'Souffle',
                          '${currentData.pef.toInt()} L/min'),
                    ),

                    const SizedBox(height: 24),
                    const MedicationCard(),

                    // Entraînement respiratoire
                    const SizedBox(height: 24),
                    _buildTrainingSection(context),

                    // Contexte & Conseils (regroupés)
                    if (!isHighRisk) ...[
                      const SizedBox(height: 24),
                      _buildContextSection(context, currentData),
                    ],

                    // Actions rapides (Bouton SOS en mode normal)
                    const SizedBox(height: 24),
                    if (!isHighRisk) _buildSOSButton(context, false),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildContextSection(BuildContext context, HealthData currentData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Icon(Icons.info_outline, color: Colors.blue.shade600),
        title: const Text(
          'Contexte & Conseils',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _suggestions.isNotEmpty 
            ? '${_suggestions.length} conseil(s) disponible(s)'
            : 'Tout est normal',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentData.symptoms.isNotEmpty) ... [
                  const Text(
                    'Symptômes signalés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildSymptomChips(currentData.symptoms),
                  const SizedBox(height: 16),
                ],
                if (currentData.temperature != null || currentData.humidity != null) ... [
                  _buildEnvironmentalSection(context, currentData),
                  const SizedBox(height: 16),
                ],
                if (_suggestions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Conseils personnalisés',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/suggestions'),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._suggestions.take(2).map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CarteSuggestion(
                      suggestion: suggestion,
                      onTap: () => Navigator.pushNamed(context, '/suggestions'),
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

  Widget _buildSOSButton(BuildContext context, bool isHighRisk) {
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
                ? [Colors.red.shade700, Colors.red.shade500]
                : [Colors.red.shade400, Colors.red.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isHighRisk ? 24 : 16),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ] else
                      Text(
                        'Alerte immédiate aux proches',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
    return Row(
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
            color:
                currentData.isBreathingRateNormal ? Colors.green : Colors.red,
            normalRange: '12-20 bpm',
            trend: breathingTrend,
            onTap: () => _showParameterDetails(
                context, 'Respiration', '${currentData.breathingRate} bpm'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentalSection(
      BuildContext context, HealthData currentData) {
    if (currentData.temperature == null && currentData.humidity == null)
      return const SizedBox.shrink();

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
              child: _buildActionButton(
                context,
                'Conseils',
                Icons.lightbulb_outline,
                () => Navigator.pushNamed(context, '/suggestions'),
                isPrimary: false,
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
          shadowColor: Colors.blue.withOpacity(0.2),
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
                      color: Colors.blue.withOpacity(0.1),
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
      default:
        return 'Paramètre de santé important.';
    }
  }
}
