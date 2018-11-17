// import 'dart:math';
// import 'dart:ui';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/material.dart';

// class Joystick extends StatefulWidget {
//   final double xPos;
//   final double yPos;
//   final ValueChanged<Offset> onChanged;

//   const Joystick({Key key, this.onChanged, this.xPos: 0.0, this.yPos: 0.0}) : super(key: key);

//   @override
//   JoystickState createState() => new JoystickState();
// }

// class JoystickState extends State<Joystick> {
//   Offset startPos;
//   double xPos = 100.0;
//   double yPos = 100.0;

//   @override
//   void initState() {
//     super.initState();

//     RenderBox getBox = context.findRenderObject();
//     startPos = Offset(getBox.get);
//   }

//   void onChanged(Offset offset) {
//     final RenderBox referenceBox = context.findRenderObject();
//     Offset position = referenceBox.globalToLocal(offset);
//     if (widget.onChanged != null) widget.onChanged(position);
//     setState(() {
//       xPos = position.dx;
//       yPos = position.dy;
//     });
//   }

//   void _handlePanStart(DragStartDetails details) {
//     setState(() {
//       startPos = details.globalPosition;
//     });
//     onChanged(details.globalPosition);
//   }

//   void _handlePanEnd(DragEndDetails details) {
//     if (startPos != null) {
//       onChanged(startPos);
//     }
//     // TODO
//   }

//   void _handlePanUpdate(DragUpdateDetails details) {
//     onChanged(details.globalPosition);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return new GestureDetector(
//       onPanStart: _handlePanStart,
//       onPanEnd: _handlePanEnd,
//       onPanUpdate: _handlePanUpdate,
//       child: new Container(
//         child: new CustomPaint(
//           size: new Size(xPos, yPos),
//           painter: new JoystickBackgroundPainter(100.0, 100.0),
//           foregroundPainter: new JoystickPainter(xPos, yPos),
//           child: new Container(
//             height: 200.0,
//             width: 200.0,
//             color: Colors.blueGrey,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class JoystickPainter extends CustomPainter {
//   static const markerRadius = 100.0;
//   final double xPos;
//   final double yPos;

//   JoystickPainter(this.xPos, this.yPos);

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawCircle(
//         new Offset(xPos, yPos),
//         markerRadius,
//         new Paint()
//           ..color = Colors.red[400]
//           ..style = PaintingStyle.fill);
//   }

//   @override
//   bool shouldRepaint(JoystickPainter old) => xPos != old.xPos && yPos != old.yPos;
// }

// class JoystickBackgroundPainter extends CustomPainter {
//   static const markerRadius = 150.0;
//   final double xPos;
//   final double yPos;

//   JoystickBackgroundPainter(this.xPos, this.yPos);

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawCircle(
//         new Offset(xPos, yPos),
//         markerRadius,
//         new Paint()
//           ..color = Colors.blue[900]
//           ..style = PaintingStyle.fill);
//   }

//   @override
//   bool shouldRepaint(JoystickBackgroundPainter old) => xPos != old.xPos && yPos != old.yPos;
// }
