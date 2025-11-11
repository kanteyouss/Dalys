import 'package:flutter/foundation.dart';
import '../../../data/models/health_data.dart';
import '../../../data/providers/mock_health_provider.dart';
import '../../../core/enums/app_enums.dart';
import 'dart:async';

class HealthController extends ChangeNotifier {
  final MockHealthProvider _mockProvider = MockHealthProvider();
  
  // État des données
  HealthData? _currentHealthData;
  List<HealthData> _historicalData = [];
  bool _isLoading = false;
  String? _error;
  
  // Stream subscription pour les données en temps réel
  StreamSubscription<HealthData>? _healthDataSubscription;

  // Getters
  HealthData? get currentHealthData => _currentHealthData;
  List<HealthData> get historicalData => _historicalData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistiques calculées
  double get averageSpo2 {
    if (_historicalData.isEmpty) return 0.0;
    final sum = _historicalData.map((e) => e.spo2).reduce((a, b) => a + b);
    return sum / _historicalData.length;
  }

  double get averageBreathingRate {
    if (_historicalData.isEmpty) return 0.0;
    final sum = _historicalData.map((e) => e.breathingRate).reduce((a, b) => a + b);
    return sum / _historicalData.length;
  }

  double get averagePef {
    if (_historicalData.isEmpty) return 0.0;
    final sum = _historicalData.map((e) => e.pef).reduce((a, b) => a + b);
    return sum / _historicalData.length;
  }

  RiskLevel get currentRiskLevel {
    return _currentHealthData?.riskLevel ?? RiskLevel.low;
  }

  /// Initialise le contrôleur et charge les données
  Future<void> initialize() async {
    await loadHealthData();
    _startRealTimeUpdates();
  }

  /// Charge les données de santé (historique + actuelle)
  Future<void> loadHealthData() async {
    try {
      _setLoading(true);
      _error = null;

      // Charger l'historique
      _historicalData = _mockProvider.getHistoricalData(days: 7);
      
      // Générer une donnée actuelle
      _currentHealthData = _mockProvider.generateRealisticHealthData();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des données: $e';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Démarre les mises à jour en temps réel
  void _startRealTimeUpdates() {
    _healthDataSubscription?.cancel();
    _healthDataSubscription = _mockProvider.getHealthDataStream().listen(
      (newData) {
        _currentHealthData = newData;
        
        // Ajouter à l'historique (garder seulement les 50 derniers points)
        _historicalData.add(newData);
        if (_historicalData.length > 50) {
          _historicalData.removeAt(0);
        }
        
        notifyListeners();
      },
      onError: (error) {
        _error = 'Erreur de connexion: $error';
        notifyListeners();
      },
    );
  }

  /// Arrête les mises à jour en temps réel
  void stopRealTimeUpdates() {
    _healthDataSubscription?.cancel();
    _healthDataSubscription = null;
  }

  /// Actualise les données manuellement
  Future<void> refreshData() async {
    await loadHealthData();
  }

  /// Ajoute une nouvelle mesure manuelle
  void addManualMeasurement({
    required int spo2,
    required int breathingRate,
    required double pef,
    required List<String> symptoms,
  }) {
    // Calculer le niveau de risque
    RiskLevel riskLevel = RiskLevel.low;
    if (spo2 < 92 || breathingRate > 24 || pef < 300) {
      riskLevel = RiskLevel.high;
    } else if (spo2 < 95 || breathingRate > 20 || pef < 350 || symptoms.isNotEmpty) {
      riskLevel = RiskLevel.medium;
    }

    final newData = HealthData(
      date: DateTime.now(),
      spo2: spo2,
      breathingRate: breathingRate,
      pef: pef,
      symptoms: symptoms,
      riskLevel: riskLevel,
    );

    _currentHealthData = newData;
    _historicalData.add(newData);
    
    // Garder seulement les 50 derniers points
    if (_historicalData.length > 50) {
      _historicalData.removeAt(0);
    }

    notifyListeners();
  }

  /// Obtient les données pour un graphique spécifique
  List<HealthData> getDataForChart(String chartType, {int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _historicalData.where((data) => data.date.isAfter(cutoffDate)).toList();
  }

  /// Vérifie si il y a des anomalies dans les données actuelles
  bool hasCurrentAnomalies() {
    if (_currentHealthData == null) return false;
    return _currentHealthData!.hasAnyAbnormalValue;
  }

  /// Obtient le nombre de jours avec des anomalies dans l'historique
  int getAnomalyDaysCount({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentData = _historicalData.where((data) => data.date.isAfter(cutoffDate)).toList();
    
    final anomalyDays = <String>{};
    for (final data in recentData) {
      if (data.hasAnyAbnormalValue) {
        final dayKey = '${data.date.year}-${data.date.month}-${data.date.day}';
        anomalyDays.add(dayKey);
      }
    }
    
    return anomalyDays.length;
  }

  /// Fonction helper pour définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
  }

  @override
  void dispose() {
    stopRealTimeUpdates();
    super.dispose();
  }
}
