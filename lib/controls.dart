import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './serverClient.dart';

class Controls extends StatefulWidget {
  Controls({Key key, this.client}) : super(key: key);
  final ServerClient client;

  @override
  _ControlsState createState() {
    return new _ControlsState();
  }
}

class _ControlsState extends State<Controls> {
  final drivingSurfaceHeight = 400.0;

  StreamSubscription serverSub;
  Offset originalOffset;
  Offset deltaPosition;
  double percentExpandedX;
  double percentExpandedY;

  @override
  void initState() {
    originalOffset = Offset(0, 0);
    deltaPosition = Offset(0, 0);
    percentExpandedX = 0.0;
    percentExpandedY = 0.0;
    serverSub = widget.client.onChange.stream.listen((_) => setState(() {}));

    super.initState();
  }

  @override
  void dispose() {
    serverSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        child: new Center(widthFactor: 1.0, child: _renderMainDrivingInterface()),
      ),
    );
  }

  _renderMainDrivingInterface() => Column(
        children: [
          _renderBox(
            child: ListTile(
              leading: Icon(FontAwesomeIcons.networkWired),
              title: Text(widget.client.isConnected ? "Connected to car" : "Disconnected from car"),
              subtitle: Text("${widget.client.signalStrength}db Ping: ${widget.client.redisLatency}ms "),
            ),
          ),
          _renderBox(
            child: ListTile(
              leading: Icon(FontAwesomeIcons.carCrash),
              title: Text('Gyro'),
              subtitle: Text(
                  "X:${widget.client.gyroX?.toStringAsPrecision(2)} Y:${widget.client.gyroY?.toStringAsPrecision(2)} Z:${widget.client.gyroZ?.toStringAsPrecision(2)}"),
            ),
          ),
          _renderBox(child: _renderDirection()),
          _renderBox(child: _renderSteeringTrim()),
          _renderDrivingSurface(),
        ],
      );

  _renderBox({@required Widget child}) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Card(child: child),
            ),
          ),
        ],
      );

  _renderSteeringTrim() => ListTile(
        leading: Icon(FontAwesomeIcons.car),
        subtitle: Slider(
          label: "Steering",
          min: -300,
          max: 300,
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey,
          value: widget.client.steerOffset.toDouble() ?? 1000.0,
          onChanged: _onSteeringTrimSet,
        ),
        title: Text("Steering Trim: ${widget.client.steerOffset}"),
      );

  _renderDirection() => ListTile(
        leading: Icon(FontAwesomeIcons.arrowCircleUp),
        subtitle: ButtonBar(
          mainAxisSize: MainAxisSize.min,
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: null,
              child: Text("FWD"),
            ),
            RaisedButton(
              onPressed: null,
              child: Text("REV"),
            ),
          ],
        ),
      );

  _renderDrivingSurface() => Expanded(
        child: CustomPaint(
          painter: new Backing(
            MediaQuery.of(context).size.width,
            drivingSurfaceHeight,
          ),
          child: GestureDetector(
            onPanStart: _startDrive,
            onPanUpdate: _continueDrive,
            onPanEnd: _endDrive,
          ),
        ),
      );

  _startDrive(DragStartDetails details) {
    setState(() {
      originalOffset = details.globalPosition;
    });
  }

  _continueDrive(DragUpdateDetails details) {
    double newPercentExpandedX =
        ((details.globalPosition.dx - originalOffset.dx) / MediaQuery.of(context).size.width) * 2;
    double newPercentExpandedY = ((details.globalPosition.dy - originalOffset.dy) / drivingSurfaceHeight) * 2;

    widget.client.setSteeringPercent(newPercentExpandedX);
    widget.client.setSpeedPercent(newPercentExpandedY * -1);
    setState(() {
      if (newPercentExpandedX.abs() <= 1.0) percentExpandedX = newPercentExpandedX;

      if (newPercentExpandedY.abs() <= 1.0) percentExpandedY = newPercentExpandedY;
    });
  }

  _endDrive(DragEndDetails details) {
    widget.client.setSpeedPercent(0);
    widget.client.setSteeringPercent(0);
    setState(() {
      originalOffset = Offset(0, 0);
      percentExpandedX = 0.0;
      percentExpandedY = 0.0;
    });
  }

  _onSteeringTrimSet(double value) => widget.client.setSteeringOffset(value.toInt());
}

class Backing extends CustomPainter {
  final double _width;
  final double _rectHeight;
  Backing(this._width, this._rectHeight);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      new Rect.fromLTRB(0.0, 0.0, this._width, _rectHeight),
      new Paint()..color = Colors.grey[800],
    );
    canvas.drawCircle(
        Offset(_width / 2, _rectHeight / 2),
        6,
        new Paint()
          ..color = Colors.amber
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill
          ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(Backing oldDelegate) {
    return false;
  }
}
