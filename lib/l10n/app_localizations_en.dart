// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DALYS';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get alerts => 'Alertes';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get chatbot => 'Health Assistant';

  @override
  String get profile => 'My Profile';

  @override
  String get share => 'Share';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get medicalDisclaimer =>
      'Warning: This application is a monitoring and prevention tool. It does not replace professional medical diagnosis. In case of emergency, contact emergency services.';

  @override
  String get generateReport => 'Generate PDF Report';

  @override
  String get environmentalData => 'Environmental Data';

  @override
  String get airQuality => 'Air Quality';

  @override
  String get weather => 'Weather';
}
