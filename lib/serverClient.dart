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
  static const direction = "move.direction";
  static const gyroX = "tele.gyro.x";
  static const gyroY = "tele.gyro.y";
  static const gyroZ = "tele.gyro.z";
  static const temp = "tele.temp";
}

// The nominal pulse timings for the car, in hz
class MotorConstants {
  static const FRONT_IDLE = 1300;
  static const FRONT_MAX = 1500;
  static const FRONT_REV = 1230;

  static const REAR_IDLE = 1600;
  static const REAR_MAX = 1600;
  static const REAR_REV = 1000;

  static const STEER_CENTER = 1200;
  static const STEER_LEFT_MAX = 800;
  static const STEER_RIGHT_MAX = 1600;
}

class ServerClient {
  /// [isConnected] returns a boolean on whether or not we are connected to the car (AKA Redis Database)
  bool get isConnected => _isConnected;
  bool _isConnected = false;

  /// [networkSSID] is the current network ID
  String get networkSSID => _networkSSID;
  String _networkSSID = "Loading...";

  /// [signalStrength] is the current strength of the wifi connection
  int get signalStrength => _signalStrength;
  int _signalStrength = 0;

  /// [redisLatency] shows the current ms delay for redis reads/writes
  int get redisLatency => _redisLatency;
  int _redisLatency = 0;

  /// [steerOffset] is an int, is an offset of the steering setting
  int get steerOffset => _steerOffset;
  int _steerOffset;

  /// [steerPercent] is the percent of the steering capability. -1.0 to +1.0
  double get steerPercent => _steerPercent;
  double _steerPercent;

  /// [motorSpeedPercent] is the percent of motor speed. -1.0 to +1.0. Negitive values should be reverse, positive should be forward.
  double get motorSpeedPercent => _motorSpeedPercent;
  double _motorSpeedPercent;

  /// Telemetry variables

  double get gyroX => _gyroX;
  double _gyroX;

  double get gyroY => _gyroY;
  double _gyroY;

  double get gyroZ => _gyroZ;
  double _gyroZ;

  double get temp => _temp;
  double _temp;

  // Server connection variables and related objects (privates)

  // the log recorder
  Logger log;

  // The server connection system to redis
  redis.Client _client;
  redis.Commands<String, String> _conn;

  // A stream to notify the UI of data changes
  StreamController onChange;

  // A periodic timer that polls network telemetry
  Timer networkStrengthHandler;

  // Our internal variables regarding actual motor speeds
  int _steerAngle;
  int _frontMotorSpeed;
  int _rearMotorSpeed;

  ServerClient({this.log}) {
    networkStrengthHandler = new Timer.periodic(Duration(seconds: 5), (_) async {
      _signalStrength = await WiFiForIoTPlugin.getCurrentSignalStrength();
      if (_conn != null) {
        Stopwatch redisLatencyTimer = Stopwatch();
        redisLatencyTimer.start();
        await _conn.ping();
        redisLatencyTimer.stop();
        _redisLatency = redisLatencyTimer.elapsedMilliseconds;
      }
      onChange.add(null);
    });

    _frontMotorSpeed = MotorConstants.FRONT_IDLE;
    _rearMotorSpeed = MotorConstants.REAR_IDLE;
    _steerAngle = MotorConstants.STEER_CENTER;

    _steerOffset = 0;
    onChange = new StreamController.broadcast();
  }

  /// Used to close down all connections on this device
  shutdownClient() {
    _client.disconnect();
    _conn = null;
    _client = null;
    onChange.close();
    networkStrengthHandler.cancel();
  }

  Future<bool> initialize(String ipToConnect) async {
    // This is always going to be our Redis address, since it is also the gateway for the network
    ipToConnect = "redis://192.168.4.1:6379";

    try {
      // Store a ref to the connections
      _client = await redis.Client.connect(ipToConnect);
      _conn = _client.asCommands<String, String>();
    } catch (e) {
      log.severe("Could not connect to redis server", e);
      return false;
    }

    _isConnected = true;

    // Set our safe values for the motors, just to be safe
    _setInitialData();

    // Start the app connection heartbeat, the car expects this, so
    // if a disconnect occurs, the car will emergency stop.
    _beginHeartbeat();

    // Start polling for the gyroscope values
    _beginTelemetryCollection();

    return true;
  }

  // Give the car some safe starting values
  _setInitialData() async {
    _conn.set(RKey.frontMotor, "$_frontMotorSpeed");
    _conn.set(RKey.rearMotor, "$_rearMotorSpeed");
    _conn.set(RKey.steering, "$_steerAngle");
  }

  // Start the timer for the heartbeat and collecting the telemetery
  Timer _beginHeartbeat() => Timer.periodic(Duration(milliseconds: 500), _sendHeartbeat);
  Timer _beginTelemetryCollection() => Timer.periodic(Duration(milliseconds: 450), _getTelemetryData);

  // The heartbeat expires and is purged after 600ms, so if the phone doesn't set this before expiration, the car will stop
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

  // Set the speed on the car from a percentage
  setSpeedPercent(double percent) async {
    // Make sure that the motor percent has changed
    if (_motorSpeedPercent != percent) {
      double frontSpeedValue;

      if (!percent.isNegative) {
        // If we should go forward
        frontSpeedValue =
            ((MotorConstants.FRONT_MAX - MotorConstants.FRONT_IDLE) * percent) + MotorConstants.FRONT_IDLE;
      } else {
        // Or if we should reverse
        frontSpeedValue =
            ((MotorConstants.FRONT_IDLE - MotorConstants.FRONT_REV) * (1 - percent.abs())) + MotorConstants.FRONT_REV;
      }
      // Round off the crazy number
      _frontMotorSpeed = frontSpeedValue.round();

      // Tell the datastore about this value
      _conn.set(RKey.frontMotor, frontSpeedValue.round().toString());

      // Trigger a UI update
      onChange.add(null);
    }
  }

  // Set the steering angle on the car from a percentage (-100% - +100%)
  setSteeringPercent(double percent) async {
    // Make sure that the motor percent has changed
    if (_steerPercent != percent) {
      // If we should turn right
      double steerSetting = 0.0;
      if (!percent.isNegative) {
        steerSetting =
            ((MotorConstants.STEER_RIGHT_MAX - MotorConstants.STEER_CENTER) * percent) + MotorConstants.STEER_CENTER;
      } else {
        steerSetting = ((MotorConstants.STEER_CENTER - MotorConstants.STEER_LEFT_MAX) * (1 - percent.abs())) +
            MotorConstants.STEER_LEFT_MAX;
      }
      _conn.set(RKey.steering, (steerSetting.round() + _steerOffset).toString());

      _steerAngle = steerSetting.round();
      onChange.add(null);
    }
  }

  // Set the offset of turning, useful for adjusting the center of the car
  setSteeringOffset(int offset) async {
    if (_steerOffset != offset) {
      setSteeringPercent(0);
      _steerOffset = offset;
      onChange.add(null);
    }
  }
}
