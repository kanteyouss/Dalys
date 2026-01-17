import 'package:flutter/material.dart';
import '../features/navigation/main_scaffold.dart';
import '../features/alertes/screens/page_alertes.dart';
import '../features/alertes/screens/page_detail_alerte.dart';
import '../features/ai_suggestions/screens/ecran_suggestions.dart';
import '../features/chatbot/screens/page_chatbot.dart';
import '../features/data_sharing/screens/share_center.dart';
import '../features/onboarding_auth/screens/login_page.dart';
import '../features/onboarding_auth/screens/register_page.dart';
import '../features/onboarding_auth/screens/profile_page.dart';
import '../features/debug/email_test_page.dart';
import '../features/health_monitoring/screens/health_history_page.dart';
import '../features/respiration/screens/ecran_respiration.dart';
import '../features/prevention/screens/fragility_score_screen.dart';
import '../data/models/modele_alerte.dart';
import '../features/health_monitoring/screens/medication_page.dart';
import '../data/services/auth_service.dart';

class AppRoutes {
  // Routes principales de l'application
  static const String tableauBord = '/tableau-bord';
  static const String alertes = '/alertes';
  static const String detailAlerte = '/detail-alerte';
  static const String suggestions = '/suggestions';
  static const String chatbot = '/chatbot';
  static const String centrePartage = '/centre-partage';
  static const String connexion = '/connexion';
  static const String inscription = '/inscription';
  static const String profil = '/profil';
  static const String historique = '/historique';
  static const String respiration = '/respiration';
  static const String medications = '/medications';
  static const String emailTest = '/email-test';
  static const String scoreSante = '/score-sante';
  static const String fragilityScore = '/fragility-score';

  // Routes héritées (compatibilité)
  static const String dashboard = '/dashboard';
  static const String alerts = '/alerts';
  static const String shareCenter = '/share-center';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      // Routes principales en français
      tableauBord: (context) => const MainScaffold(),
      alertes: (context) => const PageAlertes(),
      suggestions: (context) => const EcranSuggestions(),
      chatbot: (context) => const PageChatbot(),
      centrePartage: (context) => const ShareCenter(),
      connexion: (context) => const LoginPage(),
      inscription: (context) => const RegisterPage(),
      profil: (context) => const ProfilePage(),
      historique: (context) => const HealthHistoryPage(),
      respiration: (context) => const EcranRespiration(),
      medications: (context) => const MedicationPage(),

      // Routes héritées (compatibilité)
      dashboard: (context) => const MainScaffold(),
      alerts: (context) => const PageAlertes(),
      shareCenter: (context) => const ShareCenter(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      profile: (context) => const ProfilePage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Routes principales en français
      case tableauBord:
      case dashboard:
        return MaterialPageRoute(builder: (context) => const MainScaffold());

      case alertes:
      case alerts:
        return MaterialPageRoute(builder: (context) => const PageAlertes());

      case detailAlerte:
        // Route paramétrique pour les détails d'alerte
        if (settings.arguments is ModeleAlerte) {
          final alerte = settings.arguments as ModeleAlerte;
          return MaterialPageRoute(
            builder: (context) => PageDetailAlerte(alerte: alerte),
          );
        }
        return _routeErreur('Paramètre d\'alerte manquant');

      case suggestions:
        return MaterialPageRoute(
            builder: (context) => const EcranSuggestions());

      case chatbot:
        return MaterialPageRoute(builder: (context) => const PageChatbot());

      case centrePartage:
      case shareCenter:
        return MaterialPageRoute(builder: (context) => const ShareCenter());

      case connexion:
      case login:
        return MaterialPageRoute(builder: (context) => const LoginPage());

      case inscription:
      case register:
        return MaterialPageRoute(builder: (context) => const RegisterPage());

      case profil:
      case profile:
        return MaterialPageRoute(builder: (context) => const ProfilePage());

      case historique:
        return MaterialPageRoute(
            builder: (context) => const HealthHistoryPage());

      case respiration:
        return MaterialPageRoute(
            builder: (context) => const EcranRespiration());

      case medications:
        return MaterialPageRoute(builder: (context) => const MedicationPage());

      case emailTest:
        return MaterialPageRoute(builder: (context) => const EmailTestPage());

      case scoreSante:
      case fragilityScore:
        final userId = AuthService().currentUser?.id;
        if (userId != null) {
          return MaterialPageRoute(
            builder: (context) => FragilityScoreScreen(userId: userId),
          );
        }
        return _routeErreur('Utilisateur non connecté');

      default:
        return _routeErreur('Page introuvable');
    }
  }

  /// Génère une route d'erreur avec un message personnalisé
  static MaterialPageRoute _routeErreur(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur de navigation'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(tableauBord),
                child: const Text('Retour au tableau de bord'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
