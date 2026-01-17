import '../models/modele_alerte.dart';

/// Gestionnaire de file d'attente intelligente pour les alertes
/// Principe : "Une seule alerte à la fois" avec priorisation
class AlertQueueManager {
  static final AlertQueueManager _instance = AlertQueueManager._internal();
  factory AlertQueueManager() => _instance;
  AlertQueueManager._internal();

  final List<ModeleAlerte> _queue = [];
  ModeleAlerte? _currentAlert;
  DateTime? _lastAlertTime;
  final Map<String, DateTime> _alertCooldowns = {};
  
  // Cooldown par défaut : 24h entre 2 alertes similaires
  static const Duration _defaultCooldown = Duration(hours: 24);
  static const Duration _criticalCooldown = Duration(minutes: 5);
  static const int _maxAlertsPerDay = 3;
  
  /// Ajoute une alerte à la file avec vérification du cooldown
  bool addAlert(ModeleAlerte alert) {
    // Si alerte critique, toujours autoriser
    if (_isPriority1(alert)) {
      _clearNonCriticalAlerts();
      _queue.insert(0, alert);
      _sortQueue();
      return true;
    }
    
    // Vérifier le cooldown
    if (_isInCooldown(alert)) {
      return false; // Alerte bloquée (trop récente)
    }
    
    // Vérifier le quota quotidien
    if (_exceedsQuota()) {
      return false; // Trop d'alertes aujourd'hui
    }
    
    _queue.add(alert);
    _sortQueue();
    return true;
  }
  
  /// Récupère la prochaine alerte à afficher
  ModeleAlerte? getNextAlert() {
    if (_queue.isEmpty) return null;
    
    _currentAlert = _queue.removeAt(0);
    _lastAlertTime = DateTime.now();
    _setCooldown(_currentAlert!);
    
    return _currentAlert;
  }
  
  /// Priorités selon la matrice définie
  int _getPriority(ModeleAlerte alert) {
    // PRIORITÉ 1 : CRITIQUE (interruption immédiate)
    if (_isPriority1(alert)) return 1;
    
    // PRIORITÉ 2 : ALERTE PRÉVENTIVE (notification push)
    if (_isPriority2(alert)) return 2;
    
    // PRIORITÉ 3 : RAPPEL MÉDICAL (notification programmée)
    if (_isPriority3(alert)) return 3;
    
    // PRIORITÉ 4 : CONSEIL IA (in-app uniquement)
    if (_isPriority4(alert)) return 4;
    
    // PRIORITÉ 5 : INFORMATIONNEL (badge discret)
    return 5;
  }
  
  /// PRIORITÉ 1 : Critique (SpO₂ < 88%, FR > 30, etc.)
  bool _isPriority1(ModeleAlerte alert) {
    if (alert.type == TypeAlerte.critique) return true;
    if (alert.niveauNotification == NiveauNotification.urgence) return true;
    if (alert.niveauPriorite >= 90) return true;
    
    // Vérifier les données médicales
    final data = alert.donneesMedicales;
    if (data != null) {
      final spo2 = data['spo2'];
      final fr = data['breathing_rate'];
      if (spo2 != null && spo2 < 88) return true;
      if (fr != null && fr > 30) return true;
    }
    
    return false;
  }
  
  /// PRIORITÉ 2 : Préventive (tendance critique 24-48h, score > 85)
  bool _isPriority2(ModeleAlerte alert) {
    if (alert.tags.contains('prediction')) return true;
    if (alert.tags.contains('tendance')) return true;
    if (alert.niveauPriorite >= 70 && alert.niveauPriorite < 90) return true;
    return false;
  }
  
  /// PRIORITÉ 3 : Rappel médical
  bool _isPriority3(ModeleAlerte alert) {
    if (alert.type == TypeAlerte.medicament) return true;
    if (alert.type == TypeAlerte.rendezvous) return true;
    return false;
  }
  
  /// PRIORITÉ 4 : Conseil IA
  bool _isPriority4(ModeleAlerte alert) {
    if (alert.type == TypeAlerte.ia) return true;
    if (alert.tags.contains('conseil')) return true;
    if (alert.tags.contains('exercice')) return true;
    return false;
  }
  
  /// Trie la file selon les priorités
  void _sortQueue() {
    _queue.sort((a, b) {
      final priorityA = _getPriority(a);
      final priorityB = _getPriority(b);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Si même priorité, trier par niveauPriorite
      return b.niveauPriorite.compareTo(a.niveauPriorite);
    });
  }
  
  /// Vérifie si l'alerte est en cooldown
  bool _isInCooldown(ModeleAlerte alert) {
    final key = _getAlertKey(alert);
    final lastTime = _alertCooldowns[key];
    
    if (lastTime == null) return false;
    
    final cooldown = _isPriority1(alert) 
        ? _criticalCooldown 
        : _defaultCooldown;
        
    return DateTime.now().difference(lastTime) < cooldown;
  }
  
  /// Définit le cooldown pour une alerte
  void _setCooldown(ModeleAlerte alert) {
    final key = _getAlertKey(alert);
    _alertCooldowns[key] = DateTime.now();
  }
  
  /// Génère une clé unique pour le cooldown (basée sur le type + tags principaux)
  String _getAlertKey(ModeleAlerte alert) {
    final mainTag = alert.tags.isNotEmpty ? alert.tags.first : 'none';
    return '${alert.type.name}_$mainTag';
  }
  
  /// Vérifie si le quota quotidien est dépassé
  bool _exceedsQuota() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    final todayAlerts = _alertCooldowns.values.where((time) {
      return time.isAfter(todayStart);
    }).length;
    
    return todayAlerts >= _maxAlertsPerDay;
  }
  
  /// Efface toutes les alertes non-critiques si une critique arrive
  void _clearNonCriticalAlerts() {
    _queue.removeWhere((alert) => !_isPriority1(alert));
  }
  
  /// Réinitialise la file d'attente
  void clear() {
    _queue.clear();
    _currentAlert = null;
  }
  
  /// Nombre d'alertes en attente
  int get pendingCount => _queue.length;
  
  /// Alerte en cours d'affichage
  ModeleAlerte? get currentAlert => _currentAlert;
}
