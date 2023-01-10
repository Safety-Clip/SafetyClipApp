import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './BackgroundCollectedPage.dart';
import './BackgroundCollectingTask.dart';
import './ChatPage.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './SideMenu.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late TextEditingController _controllerPeople, _controllerMessage;
  String? _message, body;
  String _canSendSMSMessage = 'Check is not run.';
  List<String> people = [];
  var _latitude = "";
  var _longitude = "";
  var _altitude = "";
  var _speed = "";
  var _adress = "";
  
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    _controllerPeople = TextEditingController();
    _controllerMessage = TextEditingController();
  }

  Future<void> _sendSMS(List<String> recipients) async {
    print(recipients);
    final SharedPreferences prefs = await _prefs;
    Position pos = await _determinePosition();
    List pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    setState(() {
      _latitude = pos.latitude.toString();
      _longitude = pos.longitude.toString();
      _altitude = pos.altitude.toString();
      _speed = pos.speed.toString();
      _adress = '${pm[0].street}, ${pm[0].postalCode}, ${pm[0].locality}, ${pm[0].administrativeArea}';
    });
    try {
      String _result = await sendSMS(
        message: "Soheil needs your help! He is located at longitude ${_longitude}, latitude ${_latitude} and at the address ${_adress}.",
        recipients: recipients,
        sendDirect: true,
      );
      setState(() => _message = _result);
    } catch (error) {
      setState(() => _message = error.toString());
    }
  }
  
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }
  
  Future<bool> _canSendSMS() async {
    bool _result = await canSendSMS();
    setState(() => _canSendSMSMessage =
        _result ? 'This unit can send SMS' : 'This unit cannot send SMS');
    return _result;
  }

  Widget _phoneTile(String name) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
            top: BorderSide(color: Colors.grey.shade300),
            left: BorderSide(color: Colors.grey.shade300),
            right: BorderSide(color: Colors.grey.shade300),
          )),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => people.remove(name)),
                ),
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Text(
                    name,
                    textScaleFactor: 1,
                    style: const TextStyle(fontSize: 12),
                  ),
                )
              ],
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        drawer: NavDrawer(),
        appBar: AppBar(
          title: const Text('Flutter Bluetooth Serial'),
        ),
        body: Container(
          child: ListView(
            children: <Widget>[
              Divider(),
              ListTile(
                title: const Text(
                  "General",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  )
                ),
              SwitchListTile(
                title: const Text('Enable Bluetooth'),
                value: _bluetoothState.isEnabled,
                onChanged: (bool value) {
                  // Do the request and update with the true value then
                  future() async {
                    // async lambda seems to not working
                    if (value)
                      await FlutterBluetoothSerial.instance.requestEnable();
                    else
                      await FlutterBluetoothSerial.instance.requestDisable();
                  }
                  future().then((_) {
                    setState(() {});
                  });
                },
              ),
              ListTile(
                title: const Text('Bluetooth status'),
                subtitle: Text(_bluetoothState.toString()),
                trailing: ElevatedButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    FlutterBluetoothSerial.instance.openSettings();
                  },
                ),
              ),
              ListTile(
                title: const Text('Local adapter address'),
                subtitle: Text(_address),
              ),
              ListTile(
                title: const Text('Local adapter name'),
                subtitle: Text(_name),
                onLongPress: null,
              ),
              ListTile(
                title: _discoverableTimeoutSecondsLeft == 0
                    ? const Text("Discoverable")
                    : Text(
                        "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
                subtitle: const Text("PsychoX-Luna"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _discoverableTimeoutSecondsLeft != 0,
                      onChanged: null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        print('Discoverable requested');
                        final int timeout = (await FlutterBluetoothSerial.instance
                            .requestDiscoverable(60))!;
                        if (timeout < 0) {
                          print('Discoverable mode denied');
                        } else {
                          print(
                              'Discoverable mode acquired for $timeout seconds');
                        }
                        setState(() {
                          _discoverableTimeoutTimer?.cancel();
                          _discoverableTimeoutSecondsLeft = timeout;
                          _discoverableTimeoutTimer =
                              Timer.periodic(Duration(seconds: 1), (Timer timer) {
                            setState(() {
                              if (_discoverableTimeoutSecondsLeft < 0) {
                                FlutterBluetoothSerial.instance.isDiscoverable
                                    .then((isDiscoverable) {
                                  if (isDiscoverable ?? false) {
                                    print(
                                        "Discoverable after timeout... might be infinity timeout :F");
                                    _discoverableTimeoutSecondsLeft += 1;
                                  }
                                });
                                timer.cancel();
                                _discoverableTimeoutSecondsLeft = 0;
                              } else {
                                _discoverableTimeoutSecondsLeft -= 1;
                              }
                            });
                          });
                        });
                      },
                    )
                  ],
                ),
              ),
              Divider(),
              ListTile(title: const Text(
                  "Devices Discovery and Connection",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  )),
              SwitchListTile(
                title: const Text('Auto-try specific pin when pairing'),
                subtitle: const Text('Pin 1234'),
                value: _autoAcceptPairingRequests,
                onChanged: (bool value) {
                  setState(() {
                    _autoAcceptPairingRequests = value;
                  });
                  if (value) {
                    FlutterBluetoothSerial.instance.setPairingRequestHandler(
                        (BluetoothPairingRequest request) {
                      print("Trying to auto-pair with Pin 1234");
                      if (request.pairingVariant == PairingVariant.Pin) {
                        return Future.value("1234");
                      }
                      return Future.value(null);
                    });
                  } else {
                    FlutterBluetoothSerial.instance
                        .setPairingRequestHandler(null);
                  }
                },
              ),
              ListTile(
                title: ElevatedButton(
                    child: const Text('Explore discovered devices'),
                    onPressed: () async {
                      final BluetoothDevice? selectedDevice =
                          await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return DiscoveryPage();
                          },
                        ),
                      );

                      if (selectedDevice != null) {
                        print('Discovery -> selected ' + selectedDevice.address);
                      } else {
                        print('Discovery -> no device selected');
                      }
                    }),
              ),
              ListTile(
                title: ElevatedButton(
                  child: const Text('Connect to paired device to chat'),
                  onPressed: () async {
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SelectBondedDevicePage(checkAvailability: false);
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Connect -> selected ' + selectedDevice.address);
                      _startChat(context, selectedDevice);
                    } else {
                      print('Connect -> no device selected');
                    }
                  },
                ),
              ),
              Divider(),
              ListTile(title: const Text(
                  "Multiple Connections example",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  )),
              ListTile(
                title: ElevatedButton(
                  child: ((_collectingTask?.inProgress ?? false)
                      ? const Text('Disconnect and stop background collecting')
                      : const Text('Connect to start background collecting')),
                  onPressed: () async {
                    if (_collectingTask?.inProgress ?? false) {
                      await _collectingTask!.cancel();
                      setState(() {
                        /* Update for `_collectingTask.inProgress` */
                      });
                    } else {
                      final BluetoothDevice? selectedDevice =
                          await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return SelectBondedDevicePage(
                                checkAvailability: false);
                          },
                        ),
                      );

                      if (selectedDevice != null) {
                        await _startBackgroundTask(context, selectedDevice);
                        setState(() {
                          /* Update for `_collectingTask.inProgress` */
                        });
                      }
                    }
                  },
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  child: const Text('View background collected data'),
                  onPressed: (_collectingTask != null)
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return ScopedModel<BackgroundCollectingTask>(
                                  model: _collectingTask!,
                                  child: BackgroundCollectedPage(),
                                );
                              },
                            ),
                          );
                        }
                      : null,
                ),
              ),
              Divider(),
              ListTile(title: const Text(
                  "SMS Settings",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  )),
            if (people.isEmpty)
              const SizedBox(height: 0)
            else
              SizedBox(
                height: 90,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List<Widget>.generate(people.length, (int index) {
                      return _phoneTile(people[index]);
                    }),
                  ),
                ),
              ),
                ListTile(
                leading: const Icon(Icons.people),
                title: TextField(
                  controller: _controllerPeople,
                  decoration:
                      const InputDecoration(labelText: 'Add Phone Number'),
                  keyboardType: TextInputType.number,
                  onChanged: (String value) => setState(() {}),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _controllerPeople.text.isEmpty
                      ? null
                      : () => setState(() {
                            people.add(_controllerPeople.text.toString());
                            _controllerPeople.clear();
                          }),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Can send SMS'),
                subtitle: Text(_canSendSMSMessage),
                trailing: IconButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    _canSendSMS();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                        (states) => Theme.of(context).colorScheme.secondary),
                    padding: MaterialStateProperty.resolveWith(
                        (states) => const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  onPressed: () {
                    _send();
                  },
                  child: Text(
                    'SEND',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              Visibility(
                visible: _message != null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _message ?? 'No Data',
                          maxLines: null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
    BuildContext context,
    BluetoothDevice server,
  ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask!.start();
    } catch (ex) {
      _collectingTask?.cancel();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new TextButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _send() {
    if (people.isEmpty) {
      setState(() => _message = 'At Least 1 Person is Required');
    } else {
      print(people);
      _sendSMS(people);
    }
  }
}