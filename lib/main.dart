import 'package:flutter/material.dart';
import 'package:dartis/dartis.dart' as redis;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Hello Susan'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  redis.Client client;
  redis.Commands<String, String> conn;
  _init() async {
    //client = await redis.Client.connect("redis://192.168.4.1:6379");
    //conn = client.asCommands<String, String>();
  }

  @override
  _MyHomePageState createState() {
    _init();
    return new _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        widthFactor: 1.0,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new TextField(
              maxLength: 10,
              maxLines: 1,
              onChanged: _onTextChanged,
            )
          ],
        ),
      ),
    );
  }

  _onTextChanged(String text) async {
    bool success = await widget.conn.set('disp.text', text);
    print(success);
  }
}
