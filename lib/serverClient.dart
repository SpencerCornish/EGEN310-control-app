import 'dart:async';
import 'package:dartis/dartis.dart' as redis;
import 'package:logging/logging.dart';
import 'package:wifi_iot/wifi_iot.dart';

// Maps database keys to their actual values
class RKey {
  static const heartbeat = "tele.heartbeat";
  static const frontMotor = "move.speed.front";
  static const rearMotor = "move.speed.rear";
  static const steering = "move.steer";
  static const direction = "tele.heartbeat";
  static const gyroX = "tele.gyro.x";
  static const gyroY = "tele.gyro.y";
  static const gyroZ = "tele.gyro.z";
  static const temp = "tele.temp";
}

class ServerClient {
  /// [isConnected] returns a boolean on whether or not we are connected to the car (AKA Redis Database)
  bool get isConnected => _isConnected;
  bool _isConnected = false;

  String get networkSSID => _networkSSID;
  String _networkSSID = "Loading...";

  int get signalStrength => _signalStrength;
  int _signalStrength = 0;

  /// [direction] returns a boolean on whether or not we are going forward
  /// `true` = forward
  /// `false` = reverse
  bool get direction => _direction;
  bool _direction;

  /// [steerAngle] is an int, 0 is center -60 - +60
  int get steerAngle => _steerAngle;
  int _steerAngle;

  /// [frontMotorSpeed] returns a boolean on whether or not we are conencted to the car
  int get frontMotorSpeed => _frontMotorSpeed;
  int _frontMotorSpeed;

  /// [rearMotorSpeed] returns a boolean on whether or not we are conencted to the car
  int get rearMotorSpeed => _rearMotorSpeed;
  int _rearMotorSpeed;

  double get gyroX => _gyroX;
  double _gyroX;

  double get gyroY => _gyroY;
  double _gyroY;

  double get gyroZ => _gyroZ;
  double _gyroZ;

  double get temp => _temp;
  double _temp;

  // Server connection variables and related objects
  Logger log;
  redis.Client _client;
  redis.Commands<String, String> _conn;
  String ipAddress;
  StreamController onChange;
  StreamSubscription connectivitySubscription;
  Timer networkStrengthHandler;

  ServerClient({this.log, this.ipAddress: "redis://10.0.111.156:6379"}) {
    WiFiForIoTPlugin.getSSID().then((ssid) {
      _networkSSID = ssid;
      onChange.add(null);
    });
    // networkStrengthHandler = new Timer.periodic(Duration(seconds: 5), (_) async {
    //   _signalStrength = await WiFiForIoTPlugin.getCurrentSignalStrength();
    //   onChange.add(null);
    // });
    _frontMotorSpeed = 1000;
    _rearMotorSpeed = 1000;
    _steerAngle = 1200;
    onChange = new StreamController.broadcast();
    // initialize();
  }

  /// Used to close down all connections on this device
  shutdownClient() {
    _client.disconnect();
    _conn = null;
    _client = null;
    onChange.close();
    connectivitySubscription.cancel();
    networkStrengthHandler.cancel();
  }

  Future<bool> initialize(String ipToConnect) async {
    await Future.delayed(Duration(seconds: 3), () => null);
    return true;
    if (ipToConnect == null) {
      // TODO: Look into adding a search function here (For both WiFi and for Redis)
      bool didConnect = await WiFiForIoTPlugin.findAndConnect("rpi-car2", password: "TokyoEngineCake!!");
      if (didConnect) {
        ipToConnect = "redis://192.168.4.1:6379";
      } else {
        return false;
      }
    }
    try {
      _client = await redis.Client.connect(ipToConnect);
      _conn = _client.asCommands<String, String>();
    } catch (e) {
      log.severe("Could not connect to redis server", e);
      return false;
    }
    _isConnected = true;
    _setInitialData();
    _beginHeartbeat();
    _beginTelemetryCollection();
    return true;
  }

  _setInitialData() async {
    _conn.set(RKey.frontMotor, "$_frontMotorSpeed");
    _conn.set(RKey.rearMotor, "$_rearMotorSpeed");
    _conn.set(RKey.steering, "$steerAngle");
    _conn.set(RKey.direction, "$direction");
  }

  Timer _beginHeartbeat() => Timer.periodic(Duration(milliseconds: 500), _sendHeartbeat);
  Timer _beginTelemetryCollection() => Timer.periodic(Duration(seconds: 1), _getTelemetryData);

  _sendHeartbeat(Timer t) => _conn.set(RKey.heartbeat, "1", milliseconds: 600);

  _getTelemetryData(Timer t) async {
    final startTime = DateTime.now();
    final newGyroX = double.parse(await _conn.get(RKey.gyroX) ?? "0.0");
    final newGyroY = double.parse(await _conn.get(RKey.gyroY) ?? "0.0");
    final newGyroZ = double.parse(await _conn.get(RKey.gyroZ) ?? "0.0");
    final newTemp = double.parse(await _conn.get(RKey.temp) ?? "0.0");

    // If any values have changed
    if (newGyroX != _gyroX || newGyroY != _gyroY || newGyroZ != _gyroZ || newTemp != _temp) {
      _gyroX = newGyroX;
      _gyroY = newGyroY;
      _gyroZ = newGyroZ;
      _temp = newTemp;

      // Trigger a rerender
      onChange.add(null);
    }

    log.fine("updated all telemetry in ${DateTime.now().difference(startTime).inMilliseconds}ms");
  }

  setFrontMotorSpeed(int speed) {
    if (_frontMotorSpeed != speed) {
      _frontMotorSpeed = speed;
      _conn.set(RKey.frontMotor, "$speed");
      onChange.add(null);
    }
  }

  setRearMotorSpeed(int speed) {
    if (_rearMotorSpeed != speed) {
      _rearMotorSpeed = speed;
      _conn.set(RKey.rearMotor, "$speed");
      onChange.add(null);
    }
  }

  setSteeringAngle(int angle) {
    if (_steerAngle != angle) {
      _steerAngle = angle;
      _conn.set(RKey.steering, "$angle");
      onChange.add(null);
    }
  }

  setDirection(bool isForward) {
    _direction = isForward;
    _conn.set(RKey.direction, "$isForward");
    onChange.add(null);
  }
}
