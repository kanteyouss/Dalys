import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/email_config.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  Future<bool> sendEmergencyEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    String? html,
  }) async {
    debugPrint('📧 === TENTATIVE D\'ENVOI D\'EMAIL ===');
    debugPrint('📧 Destinataire: $recipientEmail');
    debugPrint('📧 Sujet: $subject');
    debugPrint('📧 Expéditeur: ${EmailConfig.senderEmail}');
    debugPrint('📧 Serveur SMTP: ${EmailConfig.smtpServer}');

    if (EmailConfig.appPassword == 'mxvp htoi fgpg pemn' ||
        EmailConfig.appPassword == 'VOTRE_CODE_DE_16_CARACTERES') {
      debugPrint(
          '⚠️ ATTENTION: Mot de passe d\'application par défaut détecté!');
    }

    final smtpServer = gmail(EmailConfig.senderEmail, EmailConfig.appPassword);

    final message = Message()
      ..from = Address(EmailConfig.senderEmail, 'DALYS Emergency')
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..text = body;

    if (html != null) {
      message.html = html;
    }

    try {
      debugPrint('📧 Connexion au serveur SMTP...');
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ Email envoyé avec succès!');
      debugPrint('📧 Rapport: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      debugPrint('❌ ERREUR MAILER: $e');
      debugPrint('❌ Type d\'erreur: ${e.runtimeType}');
      for (var p in e.problems) {
        debugPrint('❌ Problème [${p.code}]: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ ERREUR INATTENDUE: $e');
      debugPrint('❌ Type: ${e.runtimeType}');
      return false;
    }
  }
}
