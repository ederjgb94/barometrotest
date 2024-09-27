import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Para acceder al sensor de presión
import 'package:location/location.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final double _seaLevelPressure =
      1013.25; // Presión estándar al nivel del mar en hPa

  double _lastBarometerAltitude = 0.0;
  double _lastGpsAltitude = 0.0;
  String _detectedFloor = 'Indeterminado';

  // Instancia de ubicación
  final Location _location = Location();
  LocationData? _locationData;

  StreamSubscription<BarometerEvent>? _pressureSubscription;

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    // _listenToBarometer();
  }

  // Función para obtener permisos de ubicación
  Future<void> _getLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await _location.getLocation();
    setState(() {
      _lastGpsAltitude = _locationData?.altitude ?? 10.0;
    });
  }

  // Escucha del sensor barométrico
  _listenToBarometer() {
    var pressureEvents = barometerEventStream();
    _pressureSubscription = pressureEvents.listen((BarometerEvent event) {
      double pressure = event.pressure;
      setState(() {
        _lastBarometerAltitude = _calculateAltitude(pressure);
        _detectedFloor = _detectFloor(_lastBarometerAltitude, _lastGpsAltitude);
      });
    });
    return pressureEvents;
  }

  // Calcular altitud en base al barómetro
  double _calculateAltitude(double pressure) {
    double ratio = pressure / _seaLevelPressure;
    double exponent = 1 / 5.255;
    return 44330 * (1 - pow(ratio, exponent).toDouble());
  }

  // Función para detectar el piso
  String _detectFloor(double barometerAltitude, double gpsAltitude) {
    double altitudeDifference = (barometerAltitude - gpsAltitude).abs();
    print('Altitud Barómetro: $barometerAltitude, Altitud GPS: $gpsAltitude');

    if (altitudeDifference < 3) {
      return 'Primer piso';
    } else if (altitudeDifference >= 3 && altitudeDifference <= 6) {
      return 'Segundo piso';
    } else {
      return 'Altura indeterminada';
    }
  }

  @override
  void dispose() {
    _pressureSubscription?.cancel();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<BarometerEvent>(
              stream: barometerEventStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<BarometerEvent> snapshot) {
                if (snapshot.hasData) {
                  double pressure = snapshot.data!.pressure;
                  double altitude = _calculateAltitude(pressure);
                  _lastBarometerAltitude = _calculateAltitude(pressure);
                  // _detectedFloor =
                  //     _detectFloor(_lastBarometerAltitude, _lastGpsAltitude);
                  return Text(
                    'Pressure: ${pressure.toStringAsFixed(2)} hPa\n'
                    'Barometer Altitude: ${altitude.toStringAsFixed(2)} m\n'
                    'GPS Altitude: ${_lastGpsAltitude.toStringAsFixed(2)} m\n'
                    'Floor: $_detectedFloor',
                  );
                } else {
                  return const Text('No data');
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
