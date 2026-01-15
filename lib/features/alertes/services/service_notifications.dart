import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:dalys/data/models/modele_alerte.dart';
import 'service_geolocalisation.dart';

/// Service de gestion des notifications locales pour l'application E-Santé 4.0
/// Intègre la géolocalisation pour un fuseau horaire précis (Côte d'Ivoire)
class ServiceNotifications {
  /// Instance singleton du service
  static final ServiceNotifications _instance =
      ServiceNotifications._internal();
  factory ServiceNotifications() => _instance;
  ServiceNotifications._internal();

  /// Service de géolocalisation pour le fuseau horaire
  final ServiceGeolocalisation _serviceGeolocalisation =
      ServiceGeolocalisation();

  /// Plugin principal pour les notifications
  final FlutterLocalNotificationsPlugin _pluginNotifications =
      FlutterLocalNotificationsPlugin();

  /// État d'initialisation du service
  bool _estInitialise = false;

  /// Compteur pour les IDs de notifications
  int _prochainIdNotification = 1000;

  /// Obtient le fuseau horaire local via le service de géolocalisation
  Future<tz.Location> _obtenirFuseauHoraireLocal() async {
    return await _serviceGeolocalisation.obtenirFuseauHoraireOptimal();
  }

  /// Initialise le service de notifications
  /// Configure les canaux, permissions et paramètres système
  Future<bool> initialiser({BuildContext? context}) async {
    if (_estInitialise) return true;

    try {
      // Initialiser les fuseaux horaires
      tz.initializeTimeZones();

      // Initialiser le service de géolocalisation
      await _serviceGeolocalisation.initialiser();

      // Configuration Android
      const parametresInitialisationAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // Configuration iOS/macOS
      final parametresInitialisationDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        onDidReceiveLocalNotification: _gererNotificationLocaleRecue,
      );

      // Configuration Linux
      const parametresInitialisationLinux = LinuxInitializationSettings(
        defaultActionName: 'Ouvrir l\'application',
      );

      // Paramètres globaux d'initialisation
      final parametresInitialisation = InitializationSettings(
        android: parametresInitialisationAndroid,
        iOS: parametresInitialisationDarwin,
        macOS: parametresInitialisationDarwin,
        linux: parametresInitialisationLinux,
      );

      // Initialiser le plugin
      final initialise = await _pluginNotifications.initialize(
        parametresInitialisation,
        onDidReceiveNotificationResponse: _gererActionNotification,
      );

      if (initialise != true) {
        debugPrint('❌ Échec initialisation plugin notifications');
        return false;
      }

      // Créer les canaux de notification
      await _creerCanauxNotification();

      // Demander les permissions - vérifier que le context est encore valide
      final contextMonte = context?.mounted ?? false;
      final permissionsAccordees =
          await _demanderPermissions(contextMonte ? context : null);
      if (!permissionsAccordees) {
        debugPrint('⚠️ Permissions notifications limitées');
      }

      _estInitialise = true;
      debugPrint('✅ Service notifications initialisé');
      return true;
    } catch (erreur) {
      debugPrint('❌ Erreur initialisation notifications: $erreur');
      return false;
    }
  }

  /// Demande les permissions nécessaires pour les notifications
  Future<bool> _demanderPermissions(BuildContext? context) async {
    try {
      // Permission de base pour les notifications
      final statutNotifications = await Permission.notification.request();

      // Demander la géolocalisation avec dialog explicatif si contexte disponible
      bool geolocalisationAccordee = true;
      if (context != null && context.mounted) {
        geolocalisationAccordee =
            await _serviceGeolocalisation.demanderPermissionAvecDialog(context);
      }

      // Permissions spécifiques Android - utiliser détection de plateforme directe
      if (Platform.isAndroid) {
        // Permission pour les notifications exactes (Android 12+)
        final statutAlarmes = await Permission.scheduleExactAlarm.request();

        // Permission pour ignorer l'optimisation de batterie
        await Permission.ignoreBatteryOptimizations.request();

        return statutNotifications.isGranted &&
            statutAlarmes.isGranted &&
            geolocalisationAccordee;
      }

      return statutNotifications.isGranted && geolocalisationAccordee;
    } catch (erreur) {
      debugPrint('❌ Erreur demande permissions: $erreur');
      return false;
    }
  }

  /// Crée les canaux de notification avec paramètres appropriés
  Future<void> _creerCanauxNotification() async {
    final canaux = [
      // Canal pour alertes critiques
      const AndroidNotificationChannel(
        'canal_critique',
        'Alertes Critiques',
        description: 'Notifications pour les urgences médicales',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Colors.red,
      ),

      // Canal pour la prévention (proactif)
      const AndroidNotificationChannel(
        'canal_prevention',
        'Prévention & Conseils',
        description: 'Notifications proactives pour anticiper les risques',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),

      // Canal pour alertes importantes
      const AndroidNotificationChannel(
        'canal_alertes',
        'Alertes Médicales',
        description: 'Notifications pour les rappels et alertes médicaux',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),

      // Canal pour rappels médicaments
      const AndroidNotificationChannel(
        'canal_medicaments',
        'Rappels Médicaments',
        description: 'Rappels pour la prise de médicaments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        ledColor: Colors.green,
      ),

      // Canal pour rendez-vous
      const AndroidNotificationChannel(
        'canal_rendezvous',
        'Rendez-vous Médicaux',
        description: 'Rappels de rendez-vous médicaux',
        importance: Importance.high,
        playSound: true,
        enableVibration: false,
        showBadge: true,
        ledColor: Colors.blue,
      ),
    ];

    // Créer chaque canal
    for (final canal in canaux) {
      await _pluginNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(canal);
    }

    debugPrint('📢 Canaux de notification créés: ${canaux.length}');
  }

  /// Affiche une notification immédiate pour une alerte
  Future<void> afficherNotificationPourAlerte(ModeleAlerte alerte) async {
    if (!_estInitialise) {
      debugPrint('⚠️ Service notifications non initialisé');
      return;
    }

    try {
      final idNotification = _obtenirIdNotification();

      // Pour les alertes non critiques, afficher sous forme de "message" (messaging style)
      if (alerte.type != TypeAlerte.critique && Platform.isAndroid) {
        // Utiliser MessagingStyleInformation pour un rendu conversationnel
        final personneApp = Person(
          name: 'E-Santé 4.0',
          key: 'dalys_app',
          bot: true,
        );

        final messages = <Message>[];
        messages.add(Message(
          alerte.description,
          DateTime.now(),
          personneApp,
        ));

        // Utiliser BigTextStyle pour compatibilité et rendu lisible
        final bigText = '${alerte.titre}\n${alerte.description}';
        final styleInfo = BigTextStyleInformation(
          bigText,
          contentTitle: alerte.titre,
          summaryText: 'E-Santé 4.0',
        );

        final detailsAndroid = AndroidNotificationDetails(
          _obtenirCanalId(alerte),
          _obtenirNomCanal(alerte),
          channelDescription: _obtenirDescriptionCanal(alerte),
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: styleInfo,
          color: _obtenirCouleurNotification(alerte),
          playSound: true,
        );

        final detailsiOS = _configurerDetailsIOS(alerte);

        await _pluginNotifications.show(
          idNotification,
          _formaterTitreNotification(alerte),
          _formaterMessageNotification(alerte),
          NotificationDetails(
              android: detailsAndroid, iOS: detailsiOS, macOS: detailsiOS),
          payload: alerte.id,
        );

        debugPrint('💬 Notification (message) affichée: ${alerte.titre}');
      } else {
        // Comportement par défaut (critique ou plateformes non-Android)
        final detailsAndroid = _configurerDetailsAndroid(alerte);
        final detailsiOS = _configurerDetailsIOS(alerte);

        final detailsNotification = NotificationDetails(
          android: detailsAndroid,
          iOS: detailsiOS,
          macOS: detailsiOS,
        );

        // Afficher la notification
        await _pluginNotifications.show(
          idNotification,
          _formaterTitreNotification(alerte),
          _formaterMessageNotification(alerte),
          detailsNotification,
          payload: alerte.id,
        );

        debugPrint('📱 Notification affichée: ${alerte.titre}');
      }
    } catch (erreur) {
      debugPrint('❌ Erreur affichage notification: $erreur');
    }
  }

  /// Affiche une notification critique avec priorité maximale
  Future<void> afficherNotificationCritique(ModeleAlerte alerte) async {
    if (!_estInitialise) return;

    try {
      final idNotification = _obtenirIdNotification();

      // Configuration spéciale pour alertes critiques
      final detailsAndroid = AndroidNotificationDetails(
        'canal_critique',
        'Alertes Critiques',
        channelDescription:
            'Urgences médicales nécessitant une attention immédiate',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        when: alerte.dateCreation.millisecondsSinceEpoch,
        color: Colors.red,
        colorized: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alert_critique'),
        autoCancel: false, // Ne pas fermer automatiquement
        ongoing: true, // Notification persistante
        styleInformation: BigTextStyleInformation(
          alerte.description,
          htmlFormatBigText: false,
          contentTitle: alerte.titre,
          htmlFormatContentTitle: false,
          summaryText: 'E-Santé 4.0 - URGENT',
          htmlFormatSummaryText: false,
        ),
        ticker: '🚨 ALERTE CRITIQUE: ${alerte.titre}',
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );

      const detailsiOS = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alert_critique.wav',
        badgeNumber: 1,
        subtitle: 'URGENT - E-Santé 4.0',
        interruptionLevel: InterruptionLevel.critical,
        categoryIdentifier: 'ALERTE_CRITIQUE',
      );

      await _pluginNotifications.show(
        idNotification,
        '🚨 URGENT: ${alerte.titre}',
        alerte.description,
        NotificationDetails(
          android: detailsAndroid,
          iOS: detailsiOS,
          macOS: detailsiOS,
        ),
        payload: alerte.id,
      );

      debugPrint('🚨 Notification critique affichée: ${alerte.titre}');
    } catch (erreur) {
      debugPrint('❌ Erreur notification critique: $erreur');
    }
  }

  /// Programme une notification pour une date/heure spécifique
  /// Utilise le fuseau horaire local détecté par géolocalisation
  Future<void> programmerNotificationAlerte(
    ModeleAlerte alerte,
    DateTime dateProgrammee,
  ) async {
    if (!_estInitialise) return;

    try {
      final idNotification = _obtenirIdNotification();

      // Obtenir le fuseau horaire local approprié
      final fuseauLocal = await _obtenirFuseauHoraireLocal();

      // Convertir la date au fuseau local
      final dateLocaleProgrammee =
          tz.TZDateTime.from(dateProgrammee, fuseauLocal);

      debugPrint('⏰ Programmation notification:');
      debugPrint('  - Date demandée: $dateProgrammee');
      debugPrint('  - Fuseau détecté: ${fuseauLocal.name}');
      debugPrint('  - Date locale: $dateLocaleProgrammee');

      // Configuration de la notification
      final detailsAndroid = _configurerDetailsAndroid(alerte);
      final detailsiOS = _configurerDetailsIOS(alerte);

      // Programmer la notification
      await _pluginNotifications.zonedSchedule(
        idNotification,
        _formaterTitreNotification(alerte),
        _formaterMessageNotification(alerte),
        dateLocaleProgrammee,
        NotificationDetails(
          android: detailsAndroid,
          iOS: detailsiOS,
          macOS: detailsiOS,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alerte.id,
      );

      debugPrint(
          '📅 Notification programmée: ${alerte.titre} à $dateLocaleProgrammee');
    } catch (erreur) {
      debugPrint('❌ Erreur programmation notification: $erreur');
    }
  }

  /// Programme une notification récurrente
  Future<void> programmerNotificationRecurrente(
    ModeleAlerte alerte,
    RepeatInterval intervalle,
  ) async {
    if (!_estInitialise) return;

    try {
      final idNotification = _obtenirIdNotification();

      final detailsAndroid = _configurerDetailsAndroid(alerte);
      final detailsiOS = _configurerDetailsIOS(alerte);

      await _pluginNotifications.periodicallyShow(
        idNotification,
        _formaterTitreNotification(alerte),
        _formaterMessageNotification(alerte),
        intervalle,
        NotificationDetails(
          android: detailsAndroid,
          iOS: detailsiOS,
          macOS: detailsiOS,
        ),
        payload: alerte.id,
      );

      debugPrint('🔄 Notification récurrente programmée: ${alerte.titre}');
    } catch (erreur) {
      debugPrint('❌ Erreur notification récurrente: $erreur');
    }
  }

  /// Annule une notification programmée
  Future<void> annulerNotification(int idNotification) async {
    try {
      await _pluginNotifications.cancel(idNotification);
      debugPrint('❌ Notification annulée: $idNotification');
    } catch (erreur) {
      debugPrint('❌ Erreur annulation notification: $erreur');
    }
  }

  /// Annule toutes les notifications
  Future<void> annulerToutesNotifications() async {
    try {
      await _pluginNotifications.cancelAll();
      debugPrint('🗑️ Toutes les notifications annulées');
    } catch (erreur) {
      debugPrint('❌ Erreur annulation totale: $erreur');
    }
  }

  /// Méthodes privées pour la configuration

  /// Configure les détails Android de la notification
  AndroidNotificationDetails _configurerDetailsAndroid(ModeleAlerte alerte) {
    final canalId = _obtenirCanalId(alerte);
    final canalNom = _obtenirNomCanal(alerte);

    return AndroidNotificationDetails(
      canalId,
      canalNom,
      channelDescription: _obtenirDescriptionCanal(alerte),
      importance: alerte.niveauNotification == NiveauNotification.urgence
          ? Importance.max
          : (alerte.niveauNotification == NiveauNotification.prevention
              ? Importance.low
              : Importance.high),
      priority: alerte.niveauNotification == NiveauNotification.urgence
          ? Priority.high
          : (alerte.niveauNotification == NiveauNotification.prevention
              ? Priority.low
              : Priority.defaultPriority),
      showWhen: true,
      when: alerte.dateCreation.millisecondsSinceEpoch,
      color: _obtenirCouleurNotification(alerte),
      colorized: true,
      enableVibration: true,
      enableLights: true,
      ledColor: _obtenirCouleurNotification(alerte),
      playSound: true,
      styleInformation: BigTextStyleInformation(
        alerte.description,
        htmlFormatBigText: false,
        contentTitle: alerte.titre,
        htmlFormatContentTitle: false,
        summaryText: 'E-Santé 4.0',
        htmlFormatSummaryText: false,
      ),
      ticker: '${alerte.type.libelle}: ${alerte.titre}',
      category: _obtenirCategorieAndroid(alerte),
      visibility: NotificationVisibility.public,
    );
  }

  /// Configure les détails iOS/macOS de la notification
  DarwinNotificationDetails _configurerDetailsIOS(ModeleAlerte alerte) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: alerte.type == TypeAlerte.critique ? 'alert_critique.wav' : null,
      badgeNumber: 1,
      attachments: [],
      subtitle: 'E-Santé 4.0',
      interruptionLevel: alerte.type == TypeAlerte.critique
          ? InterruptionLevel.critical
          : InterruptionLevel.active,
      categoryIdentifier: _obtenirCategorieIOS(alerte),
    );
  }

  /// Méthodes utilitaires

  /// Formate le titre de la notification
  String _formaterTitreNotification(ModeleAlerte alerte) {
    final prefixe = _obtenirPrefixeType(alerte.type);
    return '$prefixe ${alerte.titre}';
  }

  /// Formate le message de la notification
  String _formaterMessageNotification(ModeleAlerte alerte) {
    if (alerte.description.length > 120) {
      return '${alerte.description.substring(0, 117)}...';
    }
    return alerte.description;
  }

  /// Obtient l'ID du canal selon le type d'alerte et le niveau de notification
  String _obtenirCanalId(ModeleAlerte alerte) {
    if (alerte.niveauNotification == NiveauNotification.urgence) {
      return 'canal_critique';
    }
    if (alerte.niveauNotification == NiveauNotification.prevention) {
      return 'canal_prevention';
    }

    switch (alerte.type) {
      case TypeAlerte.medicament:
        return 'canal_medicaments';
      case TypeAlerte.rendezvous:
        return 'canal_rendezvous';
      default:
        return 'canal_alertes';
    }
  }

  /// Obtient le nom du canal selon le type d'alerte
  String _obtenirNomCanal(ModeleAlerte alerte) {
    if (alerte.niveauNotification == NiveauNotification.urgence) {
      return 'Alertes Critiques';
    }
    if (alerte.niveauNotification == NiveauNotification.prevention) {
      return 'Prévention & Conseils';
    }

    switch (alerte.type) {
      case TypeAlerte.medicament:
        return 'Rappels Médicaments';
      case TypeAlerte.rendezvous:
        return 'Rendez-vous Médicaux';
      default:
        return 'Alertes Médicales';
    }
  }

  /// Obtient la description du canal
  String _obtenirDescriptionCanal(ModeleAlerte alerte) {
    switch (alerte.type) {
      case TypeAlerte.critique:
        return 'Urgences médicales nécessitant une attention immédiate';
      case TypeAlerte.medicament:
        return 'Rappels pour la prise de médicaments';
      case TypeAlerte.rendezvous:
        return 'Rappels de rendez-vous médicaux';
      default:
        return 'Notifications pour les alertes médicales';
    }
  }

  /// Obtient la catégorie Android de la notification
  AndroidNotificationCategory _obtenirCategorieAndroid(ModeleAlerte alerte) {
    switch (alerte.type) {
      case TypeAlerte.critique:
        return AndroidNotificationCategory.alarm;
      case TypeAlerte.medicament:
        return AndroidNotificationCategory.reminder;
      case TypeAlerte.rendezvous:
        return AndroidNotificationCategory.event;
      default:
        return AndroidNotificationCategory.status;
    }
  }

  /// Obtient la catégorie iOS de la notification
  String _obtenirCategorieIOS(ModeleAlerte alerte) {
    switch (alerte.type) {
      case TypeAlerte.critique:
        return 'ALERTE_CRITIQUE';
      case TypeAlerte.medicament:
        return 'RAPPEL_MEDICAMENT';
      case TypeAlerte.rendezvous:
        return 'RENDEZ_VOUS';
      default:
        return 'ALERTE_GENERALE';
    }
  }

  /// Obtient la couleur de notification selon le type
  Color _obtenirCouleurNotification(ModeleAlerte alerte) {
    return alerte.type.couleur;
  }

  /// Obtient le préfixe d'icône selon le type
  String _obtenirPrefixeType(TypeAlerte type) {
    switch (type) {
      case TypeAlerte.critique:
        return '🚨';
      case TypeAlerte.haute:
        return '⚠️';
      case TypeAlerte.medicament:
        return '💊';
      case TypeAlerte.rendezvous:
        return '📅';
      default:
        return '🔔';
    }
  }

  /// Obtient un nouvel ID de notification
  int _obtenirIdNotification() {
    return _prochainIdNotification++;
  }

  /// Gestionnaires d'événements

  /// Gère la réception d'une notification locale (iOS uniquement)
  void _gererNotificationLocaleRecue(
    int id,
    String? titre,
    String? corps,
    String? payload,
  ) {
    debugPrint('📱 Notification locale reçue: $titre');
  }

  /// Gère les actions sur les notifications
  void _gererActionNotification(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('👆 Action notification: $payload');

      // Navigation vers l'alerte concernée
      _naviguerVersAlerte(payload);
    }
  }

  /// Navigue vers les détails d'une alerte
  void _naviguerVersAlerte(String idAlerte) {
    // Implémentation de la navigation vers les détails de l'alerte
    try {
      NavigationService.navigateTo('/alertes/detail/$idAlerte');
    } catch (erreur) {
      debugPrint('❌ Erreur navigation alerte: $erreur');
    }
  }

  /// Informations et diagnostics

  /// Obtient les informations sur l'état du service
  Future<Map<String, dynamic>> obtenirInformationsService() async {
    final infosGeo =
        await _serviceGeolocalisation.obtenirInformationsLocalisation();

    return {
      'initialise': _estInitialise,
      'prochain_id_notification': _prochainIdNotification,
      'geolocalisation': infosGeo,
      'fuseau_horaire_detecte': (await _obtenirFuseauHoraireLocal()).name,
      'permissions_accordees': await _verifierPermissions(),
    };
  }

  /// Vérifie l'état des permissions
  Future<Map<String, bool>> _verifierPermissions() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'geolocalisation': await Permission.location.isGranted,
      'alarmes_exactes': await Permission.scheduleExactAlarm.isGranted,
      'batterie_optimisee':
          await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  /// Teste la notification avec l'alerte fournie
  Future<void> testerNotification(ModeleAlerte alerte) async {
    debugPrint('🧪 Test notification pour: ${alerte.titre}');
    await afficherNotificationPourAlerte(alerte);
  }

  /// Affiche une notification locale (alias pour compatibilité)
  Future<void> afficherNotificationLocale({
    required int id,
    required String titre,
    required String message,
    Map<String, dynamic>? donnees,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alertes_canal',
        'Alertes E-Santé',
        channelDescription: 'Notifications d\'alertes médicales',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _pluginNotifications.show(
      id,
      titre,
      message,
      details,
      payload: donnees != null ? donnees.toString() : null,
    );
  }

  /// Envoie une notification push (placeholder pour futur développement)
  Future<void> envoyerNotificationPush({
    required String destinataire,
    required String titre,
    required String message,
    Map<String, dynamic>? donnees,
  }) async {
    // TODO: Implémenter l'envoi de notifications push via Firebase ou autre
    debugPrint('📱 Notification push envoyée à $destinataire: $titre');

    // Pour l'instant, utiliser une notification locale comme fallback
    await afficherNotificationLocale(
      id: titre.hashCode,
      titre: titre,
      message: message,
      donnees: donnees,
    );
  }

  /// Annule une notification locale
  Future<void> annulerNotificationLocale(int id) async {
    await _pluginNotifications.cancel(id);
    debugPrint('🚫 Notification $id annulée');
  }

  /// Teste la connectivité du service
  Future<bool> testerConnectivite() async {
    try {
      final infos = await obtenirInformationsService();
      final initialise = infos['initialise'] as bool? ?? false;
      final permissions =
          infos['permissions_accordees'] as Map<String, bool>? ?? {};

      return initialise && (permissions['notifications'] ?? false);
    } catch (erreur) {
      debugPrint('❌ Test connectivité notifications: $erreur');
      return false;
    }
  }
}

/// Service de navigation global (à implémenter selon l'architecture)
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void navigateTo(String route) {
    navigatorKey.currentState?.pushNamed(route);
  }
}
