import 'package:flutter/material.dart';
import '../features/health_monitoring/screens/health_dashboard.dart';
import '../features/alerts/screens/alerts_page.dart';
import '../features/ai_suggestions/screens/suggestions_page.dart';
import '../features/chatbot/screens/chatbot_page.dart';
import '../features/data_sharing/screens/share_center.dart';
import '../features/onboarding_auth/screens/login_page.dart';
import '../features/onboarding_auth/screens/register_page.dart';
import '../features/onboarding_auth/screens/profile_page.dart';

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String alerts = '/alerts';
  static const String suggestions = '/suggestions';
  static const String chatbot = '/chatbot';
  static const String shareCenter = '/share-center';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      dashboard: (context) => const HealthDashboard(),
      alerts: (context) => const AlertsPage(),
      suggestions: (context) => const SuggestionsPage(),
      chatbot: (context) => const ChatbotPage(),
      shareCenter: (context) => const ShareCenter(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      profile: (context) => const ProfilePage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (context) => const HealthDashboard());
      case alerts:
        return MaterialPageRoute(builder: (context) => const AlertsPage());
      case suggestions:
        return MaterialPageRoute(builder: (context) => const SuggestionsPage());
      case chatbot:
        return MaterialPageRoute(builder: (context) => const ChatbotPage());
      case shareCenter:
        return MaterialPageRoute(builder: (context) => const ShareCenter());
      case login:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (context) => const RegisterPage());
      case profile:
        return MaterialPageRoute(builder: (context) => const ProfilePage());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page introuvable')),
            body: const Center(
              child: Text('Cette page n\'existe pas.'),
            ),
          ),
        );
    }
  }
}
