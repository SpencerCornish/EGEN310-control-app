import 'package:flutter/material.dart';

class Speed extends StatelessWidget {
  Speed({Key key, @required this.value, @required this.onUpdate, @required this.onCommit}) : super(key: key);

  final double value;
  final ValueChanged<double> onUpdate;
  final ValueChanged<double> onCommit;

  @override
  Widget build(BuildContext context) {
    return new Slider(
      min: 0.0,
      max: 10.0,
      value: value,
      onChangeEnd: onCommit,
      onChanged: onUpdate,
    );
  }
}
