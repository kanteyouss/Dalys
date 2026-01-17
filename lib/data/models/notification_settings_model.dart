import 'dart:convert';

class NotificationSettings {
  final bool vitalEmergencies;
  final bool medicationReminders;
  final bool aiForecasts;
  final bool environmentalAlertes;
  final bool voiceSynthesis;
  final bool inAppNotifications;

  NotificationSettings({
    this.vitalEmergencies = true,
    this.medicationReminders = true,
    this.aiForecasts = true,
    this.environmentalAlertes = true,
    this.voiceSynthesis = true,
    this.inAppNotifications = true,
  });

  NotificationSettings copyWith({
    bool? vitalEmergencies,
    bool? medicationReminders,
    bool? aiForecasts,
    bool? environmentalAlertes,
    bool? voiceSynthesis,
    bool? inAppNotifications,
  }) {
    return NotificationSettings(
      vitalEmergencies: vitalEmergencies ?? this.vitalEmergencies,
      medicationReminders: medicationReminders ?? this.medicationReminders,
      aiForecasts: aiForecasts ?? this.aiForecasts,
      environmentalAlertes: environmentalAlertes ?? this.environmentalAlertes,
      voiceSynthesis: voiceSynthesis ?? this.voiceSynthesis,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vitalEmergencies': vitalEmergencies,
      'medicationReminders': medicationReminders,
      'aiForecasts': aiForecasts,
      'environmentalAlertes': environmentalAlertes,
      'voiceSynthesis': voiceSynthesis,
      'inAppNotifications': inAppNotifications,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      vitalEmergencies: map['vitalEmergencies'] ?? true,
      medicationReminders: map['medicationReminders'] ?? true,
      aiForecasts: map['aiForecasts'] ?? true,
      environmentalAlertes: map['environmentalAlertes'] ?? true,
      voiceSynthesis: map['voiceSynthesis'] ?? true,
      inAppNotifications: map['inAppNotifications'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationSettings.fromJson(String source) =>
      NotificationSettings.fromMap(json.decode(source));
}
