import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';

import './serverClient.dart';
import './landing.dart';

void main() {
  // Produce logging output for debug. This only goes to the console
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord record) {
    print('${record.time} ${record.level.name} ${record.loggerName} ${record.message}');
  });

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // Create a new instance of the server connection. It isn't connected until init is called
  final client = new ServerClient(log: Logger.root);

  // This widget is the root
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return new MaterialApp(
      title: 'Car Controller',
      theme: new ThemeData(
        accentColor: Colors.deepPurpleAccent,
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: new MyHomePage(
        client: client,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.client}) : super(key: key);
  final ServerClient client;

  @override
  _MyHomePageState createState() {
    return new _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription serverSub;
  @override
  initState() {
    serverSub = widget.client.onChange.stream.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        widthFactor: 1.0,
        child: Landing(
          client: widget.client,
        ),
      ),
    );
  }

  @override
  dispose() {
    serverSub.cancel();
    super.dispose();
  }
}
