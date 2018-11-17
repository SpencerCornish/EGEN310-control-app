import 'package:flutter/material.dart';

class Direction extends StatefulWidget {
  Direction({Key key}) : super(key: key);

  @override
  _DirectionState createState() {
    return new _DirectionState();
  }
}

class _DirectionState extends State<Direction> {
  @override
  Widget build(BuildContext context) {
    return new ButtonBar(children: [
      new FlatButton(
        onPressed: _onDirectionReverse,
        color: Colors.blue,
        child: new Text("REV"),
      ),
      new FlatButton(
        onPressed: _onDirectionForward,
        child: new Text("FWD"),
      ),
    ]);
  }

  _onDirectionForward() async => null;
  _onDirectionReverse() async => null;
}
