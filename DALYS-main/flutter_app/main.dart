import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Santé 4.0',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HealthMonitorScreen(),
    );
  }
}

class HealthMonitorScreen extends StatefulWidget {
  @override
  _HealthMonitorScreenState createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController hrController = TextEditingController();
  final TextEditingController rrController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();
  final TextEditingController dustController = TextEditingController();

  // Variables pour les antécédents
  bool asthmatic = false;
  bool sensitiveHumidity = false;
  bool sensitiveDust = false;

  // Résultat de la prédiction
  String prediction = '';
  Map<String, dynamic> probabilities = {};

  // Instance pour les notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'health_channel',
      'Health Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  Future<void> _sendAlertToContacts() async {
    // Ici, vous pouvez implémenter l'envoi d'email/SMS aux proches/médecin
    // Par exemple, utiliser un service comme Twilio ou Firebase
    print('Alerte envoyée aux proches et au médecin!');
    // TODO: Implémenter l'envoi réel
  }

  Future<void> _predictRisk() async {
    final url = Uri.parse('http://YOUR_API_IP:8000/predict_risk/'); // Remplacez par l'IP de votre API

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'HR': int.parse(hrController.text),
        'RR': int.parse(rrController.text),
        'Temperature': double.parse(tempController.text),
        'Humidity': double.parse(humidityController.text),
        'Dust': int.parse(dustController.text),
        'Asthmatic': asthmatic ? 1 : 0,
        'Sensitive_Humidity': sensitiveHumidity ? 1 : 0,
        'Sensitive_Dust': sensitiveDust ? 1 : 0,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        prediction = data['prediction']['state'];
        probabilities = data['probabilities'];
      });

      // Gestion des alertes
      if (prediction == 'Risque') {
        _showNotification('Alerte Risque', 'Facteurs de risque détectés. Veuillez faire attention.');
      } else if (prediction == 'Crise') {
        _showNotification('Alerte Crise', 'Crise potentielle détectée! Action immédiate requise.');
        _sendAlertToContacts();
      }
    } else {
      setState(() {
        prediction = 'Erreur lors de la prédiction';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moniteur E-Santé 4.0'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Données des Capteurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: hrController, decoration: InputDecoration(labelText: 'Fréquence Cardiaque (HR)'), keyboardType: TextInputType.number),
              TextField(controller: rrController, decoration: InputDecoration(labelText: 'Fréquence Respiratoire (RR)'), keyboardType: TextInputType.number),
              TextField(controller: tempController, decoration: InputDecoration(labelText: 'Température'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: humidityController, decoration: InputDecoration(labelText: 'Humidité'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: dustController, decoration: InputDecoration(labelText: 'Poussière'), keyboardType: TextInputType.number),

              SizedBox(height: 20),
              Text('Antécédents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: Text('Asthmatique'),
                value: asthmatic,
                onChanged: (value) => setState(() => asthmatic = value!),
              ),
              CheckboxListTile(
                title: Text('Sensibilité à l\'humidité'),
                value: sensitiveHumidity,
                onChanged: (value) => setState(() => sensitiveHumidity = value!),
              ),
              CheckboxListTile(
                title: Text('Sensibilité à la poussière'),
                value: sensitiveDust,
                onChanged: (value) => setState(() => sensitiveDust = value!),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _predictRisk,
                child: Text('Analyser le Risque'),
              ),

              SizedBox(height: 20),
              if (prediction.isNotEmpty) ...[
                Text('Résultat de la Prédiction:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('État: $prediction', style: TextStyle(fontSize: 16)),
                Text('Probabilités:', style: TextStyle(fontSize: 16)),
                Text('Normal: ${(probabilities['Normal'] * 100).toStringAsFixed(2)}%'),
                Text('Risque: ${(probabilities['Risque'] * 100).toStringAsFixed(2)}%'),
                Text('Crise: ${(probabilities['Crise'] * 100).toStringAsFixed(2)}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}