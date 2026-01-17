import 'dart:io';
import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/health_monitoring/controllers/health_controller.dart';
import 'features/alertes/controllers/controleur_alertes.dart';
import 'features/alertes/widgets/emergency_countdown_overlay.dart';
import 'data/services/auth_service.dart';
import 'data/services/service_reconnaissance_vocale.dart';
import 'data/services/service_vocal.dart';
import 'data/models/modele_alerte.dart';
import 'data/services/medication_service.dart';
import 'data/services/notification_settings_service.dart';
import 'features/alertes/services/service_notifications.dart';

// Note: If AppLocalizations is not generated yet, this might cause a lint error.
// We keep it as it was in the original file.
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  // Initialiser les services nécessaires
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la base de données pour Desktop (Linux/Windows/macOS)
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    if (Platform.isLinux) {
      open.overrideForAll(() {
        return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
      });
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Vérifier la session persistante
  final authService = AuthService();
  final bool isLoggedIn = await authService.tryAutoLogin();
  final String initialRoute = isLoggedIn ? '/tableau-bord' : '/login';

  // Initialiser les filtres de notification pour les singletons
  final settingsService = NotificationSettingsService();

  ServiceNotifications().setSettingsService(settingsService);
  ServiceVocal().setSettingsService(settingsService);

  runApp(MyApp(initialRoute: initialRoute, settingsService: settingsService));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final NotificationSettingsService settingsService;
  const MyApp(
      {super.key, required this.initialRoute, required this.settingsService});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider(create: (_) => MedicationService()),
        ChangeNotifierProxyProvider<NotificationSettingsService,
            ControleurAlertes>(
          create: (_) => ControleurAlertes()..initialiser(),
          update: (_, settingsService, alertController) {
            alertController ??= ControleurAlertes()..initialiser();
            alertController.setSettingsService(settingsService);
            return alertController;
          },
        ),
        ChangeNotifierProxyProvider<MedicationService, ControleurAlertes>(
          create: (context) =>
              Provider.of<ControleurAlertes>(context, listen: false),
          update: (_, medicationService, alertController) {
            alertController!.setMedicationService(medicationService);
            return alertController;
          },
        ),
        ChangeNotifierProxyProvider<ControleurAlertes, HealthController>(
          create: (_) => HealthController(),
          update: (_, alertController, healthController) {
            healthController ??= HealthController();
            healthController.setControleurAlertes(alertController);
            return healthController;
          },
        ),
      ],
      child: MaterialApp(
        title: 'E-Santé 4.0 - DALYS',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return MainWrapper(child: child!);
        },
        localizationsDelegates: const [
          // AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
          Locale('en', ''),
        ],
      ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  StreamSubscription? _emergencySubscription;
  StreamSubscription? _voiceSubscription;
  final ServiceReconnaissanceVocale _voiceService =
      ServiceReconnaissanceVocale();

  @override
  void initState() {
    super.initState();

    // Attendre que le widget soit monté avant d'écouter les urgences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupEmergencyListeners();
    });
  }

  void _setupEmergencyListeners() {
    final alertController = context.read<ControleurAlertes>();
    _emergencySubscription = alertController.emergencyStream.listen((event) {
      final user = AuthService().currentUser;
      final navContext = MyApp.navigatorKey.currentContext;
      if (user != null && navContext != null && mounted) {
        EmergencyCountdownOverlay.show(navContext, user, event.title);
      }
    });

    // Écoute vocale globale pour déclencher une urgence
    _voiceService.startListening();
    _voiceSubscription = _voiceService.wordsStream.listen((word) {
      if (_voiceService.isEmergency(word)) {
        final user = AuthService().currentUser;
        final navContext = MyApp.navigatorKey.currentContext;
        if (user != null && navContext != null && mounted) {
          final declaredState = _voiceService.getDeclaredState(word);
          debugPrint('🎤 DÉCLENCHEMENT VOCAL D\'URGENCE : $declaredState');

          // Confirmation vocale immédiate pour rassurer l'utilisateur
          ServiceVocal().parler(
              "Alerte détectée. Lancement du protocole d'urgence.",
              niveau: NiveauNotification.urgence);

          EmergencyCountdownOverlay.show(navContext, user, declaredState);
        }
      }
    });
  }

  @override
  void dispose() {
    _emergencySubscription?.cancel();
    _voiceSubscription?.cancel();
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
