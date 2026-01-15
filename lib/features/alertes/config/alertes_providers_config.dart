import 'package:provider/provider.dart';
import 'package:dalys/features/alertes/providers/alertes_provider.dart';

/// Configuration des providers pour le système d'alertes
class AlertesProvidersConfig {
  /// Configure tous les providers nécessaires pour le système d'alertes
  static List<ChangeNotifierProvider> get providers => [
    ChangeNotifierProvider<AlertesProvider>(
      create: (_) => AlertesProvider(),
    ),
  ];

  /// Version statique pour ajout facile au MultiProvider
  static ChangeNotifierProvider<AlertesProvider> get alertesProvider => 
    ChangeNotifierProvider<AlertesProvider>(
      create: (_) => AlertesProvider(),
    );
}