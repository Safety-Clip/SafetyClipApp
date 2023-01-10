import 'dart:async';

import 'package:flutter/material.dart';

import 'MainPage.dart';
import 'main.dart';

class NavDrawer extends StatefulWidget{
  @override
  _NavDrawer createState() => _NavDrawer();
}

class _NavDrawer extends State<NavDrawer>{
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Side menu',
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            decoration: BoxDecoration(
                color: Colors.green,
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/images/cover.jpg'))),
          ),
          ListTile(
            leading: Icon(Icons.house),
            title: Text('Home'),
            onTap: ()  {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SafetyClipApplication()),
              );
            }
          ),
          ListTile(
            leading: Icon(Icons.explore),
            title: Text('Settings'),
            onTap: ()  {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
              );
            }
          ),
        ],
      ),
    );
  }
}