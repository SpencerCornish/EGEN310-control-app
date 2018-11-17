import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  StreamSubscription serverSub;

  @override
  void initState() {
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
          new Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.sync),
                        title: Text('Gyro Values'),
                        subtitle: Text(
                            "X:${widget.client.gyroX?.toStringAsPrecision(2)} X:${widget.client.gyroX?.toStringAsPrecision(2)} X:${widget.client.gyroX?.toStringAsPrecision(2)}"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          new Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _renderSteeringTrim(),
                ),
                Text(
                  widget.client.steerAngle.toString(),
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
          ),
          new Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _renderSpeedAdjustment(),
                ),
                Text(
                  widget.client.frontMotorSpeed.round().toString(),
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
          ),
        ],
      );

  _renderSteeringTrim() => new Slider(
        label: "Steering",
        min: 1000.0,
        max: 1700.0,
        value: widget.client.steerAngle.toDouble() ?? 1000.0,
        onChanged: _onSteeringTrimSet,
      );

  _renderSpeedAdjustment() => new Slider(
        label: "Speed",
        min: 1000.0,
        max: 1600.0,
        value: widget.client.frontMotorSpeed.toDouble() ?? 1000.0,
        onChanged: _onSpeedSet,
      );

  _onSpeedSet(double value) => widget.client.setFrontMotorSpeed(value.toInt());
  _onSteeringTrimSet(double value) => widget.client.setSteeringAngle(value.toInt());
}
