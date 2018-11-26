import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './serverClient.dart';
import './controls.dart';

class Landing extends StatefulWidget {
  Landing({Key key, this.client}) : super(key: key);
  final ServerClient client;

  @override
  _LandingState createState() {
    return new _LandingState();
  }
}

class _LandingState extends State<Landing> {
  bool connectButtonDisabled;
  StreamSubscription serverSub;

  @override
  void initState() {
    connectButtonDisabled = false;
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
        child: new Center(widthFactor: 1.0, child: _renderSetupScreen()),
      ),
    );
  }

  _renderSetupScreen() => Column(
        children: [
          new Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onDoubleTap: () => print("yee"),
                  child: new Image(
                    image: new AssetImage("assets/main_logo.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Cat's Conundrum",
                  style: TextStyle(
                    fontSize: 50.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Team Antblood",
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    connectButtonDisabled
                        ? CircularProgressIndicator()
                        : RaisedButton(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: <Widget>[
                                Text("Connect to Car"),
                              ],
                            ),
                            onPressed: _onConnectPress,
                          ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    RaisedButton(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: <Widget>[
                          Text("Demo Mode"),
                        ],
                      ),
                      onPressed: _onDemoPress,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "WiFi Network: ${widget.client.networkSSID} Strength: ${widget.client.signalStrength}",
                        style: TextStyle(fontSize: 15.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        "Current Redis Status: ${widget.client.isConnected ? 'Conneced' : 'disconnected'}",
                        style: TextStyle(fontSize: 15.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  _onDemoPress() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Controls(client: widget.client)));
  }

  _onConnectPress() async {
    setState(() {
      connectButtonDisabled = true;
    });
    bool connected = await widget.client.initialize(null);
    if (!connected) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(
          "Failed to connect! Try again",
        ),
        backgroundColor: Colors.deepOrange,
        duration: Duration(seconds: 4),
      ));
      setState(() {
        connectButtonDisabled = false;
      });
    } else {
      // Move on if the init was successful
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Controls(client: widget.client)));
    }
  }
}
