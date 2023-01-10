import 'package:flutter/material.dart';

import './MainPage.dart';
import './SideMenu.dart';

void main() => runApp(new SafetyClipApplication());

class SafetyClipApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavDrawer(),
      appBar: AppBar(
        title: Text('Safety Clip App'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text(
              "Welcome to the Safety Clip App!",
              style: TextStyle(fontSize: 40),
              textAlign: TextAlign.center,
            ),
          ),
          Divider(),
          ListTile(
            title: const Text(
              "This app is designed for your personal safety! Simply click the device attached to your waist and the app will take care of the app. All you have to do is enter some phone numbers you wish to contact.",
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.left,
            ),
          ),
          Divider(),
          ListTile(
            title: const Text(
              "Device Settings",
              style: TextStyle(fontSize: 40),
              textAlign: TextAlign.center,
            ),
          ),
          ListTile(
            title: ElevatedButton (
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}