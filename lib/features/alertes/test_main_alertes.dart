import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dalys/features/alertes/providers/alertes_provider.dart';
import 'package:dalys/features/alertes/screens/ecran_test_alertes.dart';

/// Application de test pour le système d'alertes
/// Point d'entrée principal pour valider la fonctionnalité 2
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppTestAlertes());
}

class AppTestAlertes extends StatelessWidget {
  const AppTestAlertes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AlertesProvider>(
          create: (_) => AlertesProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Test Système Alertes - E-Santé 4.0',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const EcranTestAlertes(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}