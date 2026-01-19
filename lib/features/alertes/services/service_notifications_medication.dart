import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dalys/data/models/modele_alerte.dart';
import 'service_notifications.dart';

/// Extension du ServiceNotifications pour gérer spécifiquement
/// les notifications de médicaments avec son doux et TTS
extension MedicationNotifications on ServiceNotifications {
  
  /// Programme une notification DOUCE pour un médicament
  /// ✅ Son calme (pas alarme urgence)
  /// ✅ Vibration légère
  /// ✅ Actions: Pris / Reporter / Ignorer
  /// ✅ TTS optionnel selon métadonnées
  Future<void> programmerNotificationMedicament(
    ModeleAlerte alerte,
    DateTime dateProgrammee,
  ) async {
    try {
      final idNotification = alerte.id.hashCode;

      // Configuration spécifique médicament avec son doux
      final detailsAndroid = AndroidNotificationDetails(
        'canal_medicaments', // Canal dédié avec importance modérée
        'Rappels Médicaments',
        channelDescription: 'Rappels doux pour la prise de médicaments',
        importance: Importance.high, // Visible mais pas critique
        priority: Priority.high,
        
        // 🔔 Son doux (pas alarme urgente)
        sound: const RawResourceAndroidNotificationSound('medication_reminder'),
        playSound: true,
        
        // Vibration légère et courte
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 200, 100, 200]), // Court et doux
        
        // LED verte douce
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
        ledOnMs: 500,
        ledOffMs: 500,
        
        // Style avec actions
        styleInformation: BigTextStyleInformation(
          alerte.description,
          contentTitle: alerte.titre,
          htmlFormatContentTitle: true,
          htmlFormatBigText: true,
          summaryText: '💊 Médicament',
        ),
        
        // 🎯 ACTIONS INTERACTIVES
        actions: [
          const AndroidNotificationAction(
            'pris',
            '✅ Pris',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'reporter',
            '⏰ +10 min',
            showsUserInterface: false,
            cancelNotification: false,
          ),
          const AndroidNotificationAction(
            'ignorer',
            '🔕 Ignorer',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
        
        // Persistance modérée (pas full-screen)
        ongoing: false,
        autoCancel: false,
        fullScreenIntent: false, // ❌ Pas en plein écran (réservé aux urgences)
        
        // Affichage
        showWhen: true,
        when: dateProgrammee.millisecondsSinceEpoch,
        color: const Color(0xFF4CAF50),
        colorized: true,
        
        // Catégorie Android
        category: AndroidNotificationCategory.reminder, // ✅ Type REMINDER (pas alarm/urgence)
        
        // Visibilité
        visibility: NotificationVisibility.public,
        showProgress: false,
        
        // Badge
        number: 1,
      );

      final detailsiOS = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'medication_reminder.aiff', // Son doux iOS
        badgeNumber: 1,
        threadIdentifier: 'medication',
        categoryIdentifier: 'MEDICATION_CATEGORY',
        interruptionLevel: InterruptionLevel.timeSensitive, // ✅ Important mais pas critique
      );

      // Obtenir fuseau horaire local
      final fuseauLocal = tz.local;
      final dateLocaleProgrammee = tz.TZDateTime.from(dateProgrammee, fuseauLocal);

      // Fallback Linux
      if (Platform.isLinux) {
        debugPrint('ℹ️ Notification médicament (Linux fallback): ${alerte.titre}');
        final payloadEncoded = alerte.metadonnees['payload_encoded'] as String?;
        final payload = payloadEncoded ?? alerte.id;
        await pluginNotifications.show(
          idNotification,
          alerte.titre,
          alerte.description,
          NotificationDetails(android: detailsAndroid, iOS: detailsiOS),
          payload: payload,
        );
        return;
      }

      // Programmer la notification
      // Utiliser payload encodé si disponible (avec medicationId et timeSlot)
      final payloadEncoded = alerte.metadonnees['payload_encoded'] as String?;
      final payload = payloadEncoded ?? alerte.id;
      
      await pluginNotifications.zonedSchedule(
        idNotification,
        alerte.titre,
        alerte.description,
        dateLocaleProgrammee,
        NotificationDetails(android: detailsAndroid, iOS: detailsiOS),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload, // Payload encodé avec medicationId|timeSlot
        matchDateTimeComponents: DateTimeComponents.time, // Récurrent quotidien si besoin
      );

      debugPrint('💊 Notification médicament programmée: ${alerte.titre} à ${dateLocaleProgrammee.hour}:${dateLocaleProgrammee.minute}');

      // 🗣️ Note: TTS via Future.delayed ne fonctionne pas si l'app est fermée
      // La synthèse vocale sera gérée par l'app au moment de l'ouverture de la notification
      // ou via un service background dédié si implémenté ultérieurement

    } catch (e) {
      debugPrint('❌ Erreur programmation notification médicament: $e');
    }
  }

  /// Annule une notification de médicament par son ID d'alerte
  Future<void> annulerNotificationMedicament(String alerteId) async {
    final idNotification = alerteId.hashCode;
    await pluginNotifications.cancel(idNotification);
    debugPrint('❌ Notification médicament annulée: $alerteId');
  }
}
