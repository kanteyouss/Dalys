// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DALYS';

  @override
  String get dashboard => 'Tableau de Bord';

  @override
  String get alerts => 'Alertes';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get chatbot => 'Assistant Santé';

  @override
  String get profile => 'Mon Profil';

  @override
  String get share => 'Partage';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get medicalDisclaimer =>
      'Attention : Cette application est un outil de suivi et de prévention. Elle ne remplace en aucun cas un diagnostic médical professionnel. En cas d\'urgence, contactez les services de secours.';

  @override
  String get generateReport => 'Générer un rapport PDF';

  @override
  String get environmentalData => 'Données Environnementales';

  @override
  String get airQuality => 'Qualité de l\'air';

  @override
  String get weather => 'Météo';
}
