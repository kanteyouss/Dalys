import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import '../../core/enums/app_enums.dart';

/// Service responsable de la communication avec les capteurs ESP32
/// (DHT22, MAX30100, DS18B20)
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // UUIDs des services et caractéristiques (à adapter selon votre firmware ESP32)
  // UUID standard pour UART Service (Nordic) souvent utilisé
  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_RX = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Receive
  static const String CHARACTERISTIC_TX = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // Transmit

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;
  
  StreamController<HealthData>? _dataController;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;

  /// Tente de se connecter à l'ESP32 (via Bluetooth ou WiFi)
  Future<bool> connect() async {
    try {
      // 1. Vérifier si Bluetooth est activé
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        print("Bluetooth éteint");
        return false;
      }

      // 2. Scanner pour trouver l'ESP32
      print("Démarrage du scan...");
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        withServices: [Guid(SERVICE_UUID)], // Filtrer par service si possible
      );

      // Chercher le device dans le stream de scan
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.platformName == "DALYS_ESP32" || r.device.platformName.contains("DALYS")) {
            print("Appareil trouvé: ${r.device.platformName}");
            await FlutterBluePlus.stopScan();
            await _connectToDevice(r.device);
            break;
          }
        }
      });

      // Attendre un peu pour laisser le temps de trouver
      await Future.delayed(const Duration(seconds: 5));
      
      return _isConnected;
    } catch (e) {
      print("Erreur de connexion: $e");
      return false;
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // await device.connect();
      // _device = device;
      // _isConnected = true;

      // // Découvrir les services
      // List<BluetoothService> services = await device.discoverServices();
      // for (BluetoothService service in services) {
      //   if (service.uuid.toString().toUpperCase() == SERVICE_UUID) {
      //     for (BluetoothCharacteristic c in service.characteristics) {
      //       if (c.uuid.toString().toUpperCase() == CHARACTERISTIC_TX) {
      //         _rxCharacteristic = c;
      //         _startListening();
      //       }
      //     }
      //   }
      // }
      
      // // Écouter l'état de connexion
      // _connectionSubscription = device.connectionState.listen((state) {
      //   if (state == BluetoothConnectionState.disconnected) {
      //     disconnect();
      //   }
      // });

    } catch (e) {
      print("Erreur lors de la connexion au device: $e");
      disconnect();
    }
  }

  /// Déconnecte les capteurs
  Future<void> disconnect() async {
    _isConnected = false;
    _dataController?.close();
    _dataController = null;
  }

  /// Stream de données provenant des capteurs
  Stream<HealthData> get sensorStream {
    _dataController ??= StreamController<HealthData>.broadcast();
    return _dataController!.stream;
  }

  /// Simule la réception de données (à remplacer par le parsing réel)
  void _startListening() {
    if (!_isConnected) return;

    // Simulation de réception de données toutes les 5 secondes
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Ici, on parserait les données reçues de l'ESP32
      // Format attendu JSON: {"spo2": 98, "bpm": 72, "temp": 37.2, "hum": 45, "env_temp": 24}
      
      // Pour l'instant, on ne fait rien car c'est un placeholder
      // Le contrôleur utilisera le MockProvider en mode simulation
    });
  }
  
  /// Méthode pour parser les données brutes reçues de l'ESP32
  HealthData parseSensorData(Map<String, dynamic> data) {
    final spo2 = data['spo2'] as int;
    final bpm = data['bpm'] as int;
    final temp = (data['temp'] as num).toDouble();
    final envTemp = (data['env_temp'] as num).toDouble();
    final humidity = (data['hum'] as num).toDouble();
    
    // Calcul basique du risque
    RiskLevel risk = RiskLevel.low;
    if (spo2 < 92 || bpm > 100 || temp > 38.5) {
      risk = RiskLevel.high;
    } else if (spo2 < 95 || bpm > 90 || temp > 37.8) {
      risk = RiskLevel.medium;
    }

    return HealthData(
      date: DateTime.now(),
      spo2: spo2,
      breathingRate: 16, // Le MAX30100 ne donne pas la fréq respi, il faut l'estimer ou utiliser un autre capteur
      pef: 0, // Nécessite un capteur de débit
      temperature: temp,
      humidity: humidity,
      envTemperature: envTemp,
      symptoms: [],
      riskLevel: risk,
    );
  }
}
