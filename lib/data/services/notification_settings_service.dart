import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings_model.dart';

class NotificationSettingsService extends ChangeNotifier {
  static const String _storageKey = 'notification_settings';
  NotificationSettings _settings = NotificationSettings();

  NotificationSettings get settings => _settings;

  NotificationSettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_storageKey);
      if (settingsJson != null) {
        _settings = NotificationSettings.fromJson(settingsJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement des paramètres de notification: $e');
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _settings.toJson());
    } catch (e) {
      debugPrint(
          'Erreur lors de la sauvegarde des paramètres de notification: $e');
    }
  }

  /// Vérifie si une notification spécifique est autorisée
  bool isNotificationEnabled(String category) {
    switch (category) {
      case 'vital':
        return _settings.vitalEmergencies;
      case 'medication':
        return _settings.medicationReminders;
      case 'forecast':
        return _settings.aiForecasts;
      case 'environment':
        return _settings.environmentalAlertes;
      case 'voice':
        return _settings.voiceSynthesis;
      case 'in_app':
        return _settings.inAppNotifications;
      default:
        return true;
    }
  }
}
