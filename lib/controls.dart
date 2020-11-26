import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './serverClient.dart';

// Defines the parent widget, which will be rendered when the route references an instance of this class
class Controls extends StatefulWidget {
  Controls({Key key, this.client}) : super(key: key);
  final ServerClient client;

  @override
  _ControlsState createState() {
    return new _ControlsState();
  }
}

class _ControlsState extends State<Controls> {
  // The height of the drag plane used for controlling the car, in pixels
  final drivingSurfaceHeight = 400.0;

  // This subscribes us to the datasource container
  // When this fires, a rerender of the UI is triggered
  StreamSubscription serverSub;

  // Where the drag starts
  Offset dragStartOffset;

  // Change in drag position from the start offset
  Offset deltaPosition;

  // Modifier for how much we should reduce the speed sent to the car
  // e.g. user speed value is 70%, reduction is 20%, value sent is 50%
  double percentSpeedReduction;

  @override
  void initState() {
    dragStartOffset = Offset(0, 0);
    deltaPosition = Offset(0, 0);
    percentSpeedReduction = 0;

    // Trigger a UI update when the onChange stream fires
    serverSub = widget.client.onChange.stream.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    // Cancel our subscription when this page closes
    serverSub.cancel();
    super.dispose();
  }

  @override
  // Render all of the individual components of the app
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        child: new Center(
          widthFactor: 1.0,
          child: Column(
            children: [
              _renderBox(child: _renderNetworkInfo()),
              _renderBox(child: _renderGyroInfo()),
              _renderBox(child: _renderDragReducer()),
              _renderBox(child: _renderSteeringTrim()),
              _renderDrivingSurface(),
            ],
          ),
        ),
      ),
    );
  }

  // Renders the network info panel content
  _renderNetworkInfo() => ListTile(
        leading: Icon(FontAwesomeIcons.networkWired),
        title: Text(widget.client.isConnected ? "Connected to car" : "Disconnected from car"),
        subtitle: Text("${widget.client.signalStrength}db Ping: ${widget.client.redisLatency}ms "),
      );

  // Renders the gyroscopic sensor info panel content
  _renderGyroInfo() => ListTile(
      leading: Icon(FontAwesomeIcons.carCrash),
      title: Text('Gyro'),
      subtitle: Text(
          "X:${widget.client.gyroX?.toStringAsPrecision(2)} Y:${widget.client.gyroY?.toStringAsPrecision(2)} Z:${widget.client.gyroZ?.toStringAsPrecision(2)}"));

  // Renders the trim setter for steering, to adjust the center point of the steering
  _renderSteeringTrim() => ListTile(
        leading: Icon(FontAwesomeIcons.car),
        subtitle: Slider(
          label: "Steering",
          min: -500,
          max: 500,
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey,
          value: widget.client.steerOffset.toDouble() ?? 0,
          onChanged: _onSteeringTrimSet,
        ),
        title: Text("Steering Trim: ${widget.client.steerOffset}"),
      );

  // Renders the drag reducer component. This is used to reduce the sensitivity of the driving surface
  _renderDragReducer() => ListTile(
        leading: Icon(FontAwesomeIcons.car),
        subtitle: Slider(
          label: "Speed reducer",
          min: 0,
          max: 100,
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey,
          value: percentSpeedReduction,
          onChanged: _onSteeringTrimSet,
        ),
        title: Text("% speed sensitivity reduction: $percentSpeedReduction%"),
      );

  // Renders a touch-sensitive canvas that allows for driving by drag
  _renderDrivingSurface() => Expanded(
        child: CustomPaint(
          painter: new Backing(
            MediaQuery.of(context).size.width, // Gets the width of the screen
            drivingSurfaceHeight,
          ),
          child: GestureDetector(
            onPanStart: _startDrag,
            onPanUpdate: _continueDrag,
            onPanEnd: _endDrag,
          ),
        ),
      );

  // Render a box to put other components inside
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

  // Tells the server client how to offset the steering trim
  _onSteeringTrimSet(double value) => widget.client.setSteeringOffset(value.toInt());

  // Records the initial point of contact by a dragging finger
  _startDrag(DragStartDetails details) {
    // Trigger UI update
    setState(() {
      dragStartOffset = details.globalPosition;
    });
  }

  // Updates the percent distance moved by the finger to update the car on what speed it should be going
  _continueDrag(DragUpdateDetails details) {
    double newPercentExpandedX =
        ((details.globalPosition.dx - dragStartOffset.dx) / MediaQuery.of(context).size.width) * 2;
    double newPercentExpandedY = ((details.globalPosition.dy - dragStartOffset.dy) / drivingSurfaceHeight) * 2;

    // send the data to the translator class, to be packaged and sent to the car
    widget.client.setSteeringPercent(newPercentExpandedX);
    widget.client.setSpeedPercent(newPercentExpandedY * -1);

    // Trigger UI update
    setState(() {});
  }

  // Resets when the finger leaves the screen
  _endDrag(DragEndDetails details) {
    // Stop the car
    widget.client.setSpeedPercent(0);
    widget.client.setSteeringPercent(0);

    // Trigger UI update
    setState(() {
      dragStartOffset = Offset(0, 0);
    });
  }
}

// The background of the canvas where car control occurs
class Backing extends CustomPainter {
  final double _width;
  final double _rectHeight;
  Backing(this._width, this._rectHeight);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a big grey rectangle
    canvas.drawRect(
      new Rect.fromLTRB(0.0, 0.0, this._width, _rectHeight),
      new Paint()..color = Colors.grey[800],
    );
    // Draw a little centering circle, just so we can get a nifty centerpoint
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
    // We never want to repaint this, as it is stateless
    return false;
  }
}
