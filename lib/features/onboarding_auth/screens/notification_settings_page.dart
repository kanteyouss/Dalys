import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/notification_settings_service.dart';
import '../../../data/models/notification_settings_model.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Notifications'),
        elevation: 0,
      ),
      body: Consumer<NotificationSettingsService>(
        builder: (context, service, child) {
          final settings = service.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(
                'Contrôlez vos alertes pour une expérience sereine et sécurisée.',
                theme,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('SÉCURITÉ & SANTÉ', theme),
              _buildSettingCard([
                _buildSwitchTile(
                  title: 'Urgences Vitales',
                  subtitle: 'Alertes critiques (SpO2 basse, détresse)',
                  icon: Icons.emergency_share,
                  color: Colors.red,
                  value: settings.vitalEmergencies,
                  onChanged: (val) => _update(context, service,
                      settings.copyWith(vitalEmergencies: val)),
                  isCritical: true,
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Rappels Médicaments',
                  subtitle: 'Suivi de votre traitement quotidien',
                  icon: Icons.medication,
                  color: Colors.green,
                  value: settings.medicationReminders,
                  onChanged: (val) => _update(context, service,
                      settings.copyWith(medicationReminders: val)),
                ),
              ], theme),
              const SizedBox(height: 24),
              _buildSectionTitle('INTELLIGENCE & PRÉVENTION', theme),
              _buildSettingCard([
                _buildSwitchTile(
                  title: 'Prévisions IA',
                  subtitle: 'Anticipation des risques à 24h et 7j',
                  icon: Icons.psychology,
                  color: Colors.blue,
                  value: settings.aiForecasts,
                  onChanged: (val) => _update(
                      context, service, settings.copyWith(aiForecasts: val)),
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Alertes Environnement',
                  subtitle: 'Température, humidité, qualité de l\'air',
                  icon: Icons.thermostat,
                  color: Colors.orange,
                  value: settings.environmentalAlertes,
                  onChanged: (val) => _update(context, service,
                      settings.copyWith(environmentalAlertes: val)),
                ),
              ], theme),
              const SizedBox(height: 24),
              _buildSectionTitle('PRÉFÉRENCES D\'INTERFACE', theme),
              _buildSettingCard([
                _buildSwitchTile(
                  title: 'Synthèse Vocale',
                  subtitle: 'Lecture à voix haute des alertes',
                  icon: Icons.record_voice_over,
                  color: Colors.purple,
                  value: settings.voiceSynthesis,
                  onChanged: (val) => _update(
                      context, service, settings.copyWith(voiceSynthesis: val)),
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Notifications In-App',
                  subtitle: 'Messages de confirmation et infos',
                  icon: Icons.info_outline,
                  color: Colors.teal,
                  value: settings.inAppNotifications,
                  onChanged: (val) => _update(context, service,
                      settings.copyWith(inAppNotifications: val)),
                ),
              ], theme),
              const SizedBox(height: 32),
              _buildDisclaimer(theme),
            ],
          );
        },
      ),
    );
  }

  void _update(BuildContext context, NotificationSettingsService service,
      NotificationSettings newSettings) {
    service.updateSettings(newSettings);
  }

  Widget _buildHeader(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: theme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isCritical = false,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      activeColor: color,
    );
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Note : Désactiver certaines notifications peut réduire la réactivité du système en cas de besoin. Les alertes critiques restent recommandées.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF795548),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
