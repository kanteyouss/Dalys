import 'package:flutter/material.dart';
import '../../data/services/service_email.dart';
import '../../core/config/email_config.dart';

class EmailTestPage extends StatefulWidget {
  const EmailTestPage({super.key});

  @override
  State<EmailTestPage> createState() => _EmailTestPageState();
}

class _EmailTestPageState extends State<EmailTestPage> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  String _result = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendTestEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _result = '❌ Veuillez entrer un email de destination';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _result = '📧 Envoi en cours...';
    });

    final success = await EmailService().sendEmergencyEmail(
      recipientEmail: _emailController.text.trim(),
      subject: 'Test DALYS - Email d\'urgence',
      body: 'Ceci est un email de test envoyé depuis l\'application DALYS.',
      html: '''
        <div style="font-family: sans-serif; padding: 20px;">
          <h2 style="color: #1976d2;">✅ Test DALYS</h2>
          <p>Si vous recevez cet email, la configuration SMTP fonctionne correctement!</p>
          <p><strong>Expéditeur:</strong> ${EmailConfig.senderEmail}</p>
          <p><strong>Serveur:</strong> ${EmailConfig.smtpServer}</p>
        </div>
      ''',
    );

    setState(() {
      _isSending = false;
      _result = success
          ? '✅ Email envoyé avec succès!\nVérifiez la boîte de réception de ${_emailController.text}'
          : '❌ Échec de l\'envoi.\nConsultez les logs dans la console pour plus de détails.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test d\'envoi d\'email'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.email, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Test de configuration SMTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Configuration actuelle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration actuelle',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildConfigRow('Expéditeur', EmailConfig.senderEmail),
                    _buildConfigRow('Serveur SMTP', EmailConfig.smtpServer),
                    _buildConfigRow('Port', EmailConfig.smtpPort.toString()),
                    _buildConfigRow(
                      'Mot de passe',
                      EmailConfig.appPassword == 'mxvp htoi fgpg pemn'
                          ? '⚠️ Par défaut (à changer!)'
                          : '✅ Configuré',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Formulaire de test
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email de test',
                hintText: 'votre.email@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendTestEmail,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Envoi...' : 'Envoyer un email de test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Résultat
            if (_result.isNotEmpty)
              Card(
                color: _result.contains('✅')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 16,
                      color: _result.contains('✅')
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Instructions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                        '1. Vérifiez que le mot de passe d\'application Gmail est correct'),
                    SizedBox(height: 8),
                    Text('2. Entrez votre email pour recevoir un test'),
                    SizedBox(height: 8),
                    Text('3. Cliquez sur "Envoyer"'),
                    SizedBox(height: 8),
                    Text(
                        '4. Consultez les logs dans la console pour plus de détails'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
