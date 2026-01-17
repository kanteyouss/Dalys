import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/fragility_models.dart';
import '../../../data/models/actionable_recommendation.dart';
import '../../../data/services/fragility_score_service.dart';
import '../../../data/services/personalized_prevention_service.dart';
import '../../../data/services/database_service.dart';
import '../../../data/models/health_data.dart';
import '../../../data/models/patient_risk_profile.dart';
import '../../../core/enums/app_enums.dart';

/// Écran de visualisation du score de fragilité et recommandations
class FragilityScoreScreen extends StatefulWidget {
  final int userId;

  const FragilityScoreScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<FragilityScoreScreen> createState() => _FragilityScoreScreenState();
}

class _FragilityScoreScreenState extends State<FragilityScoreScreen> {
  final FragilityScoreService _fragilityService = FragilityScoreService();
  final PersonalizedPreventionService _preventionService =
      PersonalizedPreventionService();
  final DatabaseService _dbService = DatabaseService();

  FragilityScore? _currentScore;
  List<ActionableRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFragilityData();
  }

  Future<void> _loadFragilityData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'historique
      final history = await _getHealthHistory(widget.userId);
      
      // Récupérer le profil
      final profile = PatientRiskProfile.createDefault(widget.userId);
      
      // Calculer le score
      final score = await _fragilityService.calculateCurrentFragility(
        history,
        profile,
      );

      // Récupérer les recommandations
      final recommendations =
          await _preventionService.getActionableRecommendations(
        profile,
        history.isNotEmpty ? history.last : _createDummyData(),
        history,
      );

      setState(() {
        _currentScore = score;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<List<HealthData>> _getHealthHistory(int userId) async {
    final db = await _dbService.database;
    
    // Récupérer TOUTES les données de l'utilisateur (pas seulement 14 jours)
    // Pour s'aligner avec la logique du dashboard qui fonctionne
    final results = await db.query(
      'health_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 50,  // Plus de données pour meilleure analyse
    );

    debugPrint('🔍 FragilityScoreScreen: ${results.length} données trouvées pour userId=$userId');

    if (results.isEmpty) {
      debugPrint('⚠️ Aucune donnée en DB, création de données par défaut');
      return [_createDummyData()];
    }

    // Convertir et trier chronologiquement (même logique que dashboard)
    final history = results.map((row) {
      // Utiliser la méthode fromJson native du modèle
      // mais adapter le format des symptoms depuis la DB
      final Map<String, dynamic> adaptedRow = Map.from(row);
      
      // Conversion des symptoms de String vers List<String>
      if (adaptedRow['symptoms'] is String) {
        final symptomsString = adaptedRow['symptoms'] as String;
        adaptedRow['symptoms'] = symptomsString.isEmpty 
            ? <String>[]
            : symptomsString.split(',');
      }
      
      return HealthData.fromJson(adaptedRow);
    }).toList();
    
    // Trier chronologiquement (plus ancien en premier)
    history.sort((a, b) => a.date.compareTo(b.date));
    
    debugPrint('✅ ${history.length} données converties et triées');
    return history;
  }

  HealthData _createDummyData() {
    return HealthData(
      userId: widget.userId,
      date: DateTime.now(),
      spo2: 96,
      breathingRate: 18,
      pef: 400,
      symptoms: [],
      riskLevel: RiskLevel.low,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score de Fragilité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFragilityData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFragilityData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentScore != null) ...[
                      _buildScoreCard(),
                      const SizedBox(height: 24),
                      _buildFactorsSection(),
                      const SizedBox(height: 24),
                      _buildRecommendationsSection(),
                      const SizedBox(height: 24),
                      _buildActionsSection(),
                    ] else
                      const Center(child: Text('Aucune donnée disponible')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScoreCard() {
    final score = _currentScore!;
    final color = _getScoreColor(score.level);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              score.level.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              '${score.value.toStringAsFixed(0)}/100',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              score.level.label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.level.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildNextReviewInfo(score.nextReviewIn),
          ],
        ),
      ),
    );
  }

  Widget _buildNextReviewInfo(Duration nextReview) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Prochaine évaluation: ${_formatDuration(nextReview)}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsSection() {
    final factors = _currentScore!.factors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Facteurs Contributifs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...factors.map((factor) => _buildFactorCard(factor)),
      ],
    );
  }

  Widget _buildFactorCard(RiskFactor factor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContributionColor(factor.contribution),
          child: Text(
            '+${factor.contribution.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          factor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(factor.explanation),
            if (factor.evidence != null) ...[
              const SizedBox(height: 4),
              Text(
                '📊 ${factor.evidence}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _currentScore!.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          return _buildRecommendationItem(index + 1, rec);
        }),
      ],
    );
  }

  Widget _buildRecommendationItem(int number, String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions à Prendre',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._recommendations.take(5).map((rec) => _buildActionCard(rec)),
      ],
    );
  }

  Widget _buildActionCard(ActionableRecommendation rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: rec.isCritical ? Colors.red.shade50 : null,
      child: ListTile(
        leading: Icon(
          rec.isCritical ? Icons.warning : Icons.check_circle_outline,
          color: rec.isCritical ? Colors.red : Colors.green,
          size: 32,
        ),
        title: Text(
          rec.action,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: rec.isCritical ? Colors.red.shade900 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  rec.timeRemainingLabel,
                  style: TextStyle(
                    color: rec.isOverdue ? Colors.red : Colors.grey[700],
                    fontWeight:
                        rec.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${rec.estimatedDuration.inMinutes} min'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '✓ ${rec.successCriteria}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            'Priorité ${rec.priority}',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: _getPriorityColor(rec.priority),
        ),
      ),
    );
  }

  Color _getScoreColor(FragilityLevel level) {
    switch (level) {
      case FragilityLevel.stable:
        return Colors.green;
      case FragilityLevel.moderate:
        return Colors.orange;
      case FragilityLevel.elevated:
        return Colors.deepOrange;
      case FragilityLevel.critical:
        return Colors.red;
    }
  }

  Color _getContributionColor(double contribution) {
    if (contribution >= 20) return Colors.red;
    if (contribution >= 10) return Colors.orange;
    return Colors.amber;
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 9) return Colors.red.shade100;
    if (priority >= 7) return Colors.orange.shade100;
    return Colors.green.shade100;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }
}
