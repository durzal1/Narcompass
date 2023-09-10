import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drug/main.dart';
import 'package:drug/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:settings_ui/settings_ui.dart';

void main() {
  runApp(MaterialApp(
    title: 'settings_page',
    home: SettingsPage(),
  ));
}

class SettingsPage extends StatefulWidget {
  // ignore: public_member_api_docs
  SettingsPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

// ignore: camel_case_types
class _SettingsPageState extends State<SettingsPage> {
  final radiusInputController = TextEditingController();
  TextEditingController _textInputController = TextEditingController();
  String storedValue = '';
  @override
  void initState() {
    // TODO: implement initState
  }

  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Settings'),
  //       backgroundColor: Colors.grey.shade50,
  //     ),
  //     body: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start, // Left-align widgets
  //       children: <Widget>[
  //         SizedBox(
  //           width: double.infinity, // Make the button expand horizontally

  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               shadowColor: Colors.redAccent.shade700,

  //               padding: EdgeInsets.all(20.0), // Increase padding for size
  //             ),
  //             child: const Text(
  //               'Back to Map',
  //               style: TextStyle(fontSize: 20.0), // Increase font size
  //             ),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => MyApp()),
  //               );
  //             },
  //           ),
  //         ),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.grey,
  //               shadowColor: Colors.redAccent.shade700,
  //               padding: EdgeInsets.all(20.0),
  //             ),
  //             child: const Text(
  //               'Profile',
  //               style: TextStyle(fontSize: 20.0),
  //             ),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => const ProfilePage()),
  //               );
  //             },
  //           ),
  //         ),
  //         Expanded(
  //           child: Positioned(
  //             top: 30,
  //             child: Container(
  //               child: Flexible(
  //                 flex: 1,
  //                 child: ToggleSwitch(
  //                   activeBorders: [
  //                     Border.all(
  //                       color: Colors.red,
  //                       width: 3.0,
  //                     ),
  //                     Border.all(
  //                       color: Colors.red.shade500,
  //                       width: 3.0,
  //                     ),
  //                   ],
  //                   initialLabelIndex: 0,
  //                   totalSwitches: 2,
  //                   labels: ['Driving Mode', 'Walking Mode'],
  //                   minWidth: 700,
  //                   centerText: true,
  //                   activeBgColor: [Color.fromARGB(255, 206, 27, 14)],
  //                   activeFgColor: Colors.black54,
  //                   fontSize: 20,
  //                   multiLineText: true,
  //                   onToggle: (index) {
  //                     isDrivingSwitched = !isDrivingSwitched;
  //                     if (isDrivingSwitched) {
  //                       travelmode = TravelMode.driving;
  //                     } else {
  //                       travelmode = TravelMode.walking;
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //         SizedBox(
  //           width: double.infinity,
  //           child: TextField(
  //             decoration: const InputDecoration(
  //               border: OutlineInputBorder(),
  //               hintText: 'Radius',
  //             ),
  //             keyboardType: TextInputType.number,
  //             controller: radiusInputController,
  //             style: TextStyle(fontSize: 20.0), // Increase font size
  //           ),
  //         ),
  //         SizedBox(
  //           width: double.infinity,
  //           child: TextButton(
  //             style: TextButton.styleFrom(
  //               padding: EdgeInsets.all(20.0),
  //             ),
  //             child: const Text(
  //               'Save Changes',
  //               style: TextStyle(fontSize: 20.0),
  //             ),
  //             onPressed: () {
  //               global_radius = double.parse(radiusInputController.text);
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    String selectedValue = "1.0";
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          ),
        ),
        title: Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: Icon(Icons.person_2_outlined),
                title: Text('Profile'),
                value: Text('Click to View'),
                onPressed: (BuildContext context) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Route'),
            tiles: <SettingsTile>[
              SettingsTile.switchTile(
                onToggle: (value) {
                  if (value) {
                    travelmode = TravelMode.driving;
                  } else {
                    travelmode = TravelMode.walking;
                  }
                },
                initialValue: true,
                leading: Icon(Icons.car_crash),
                title: Text('Driving Mode Toggle'),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Radius Input (KM)'),
            tiles: <SettingsTile>[
              SettingsTile(
                title: Text('Select an Option'),
                leading: Icon(Icons.arrow_drop_down),
                onPressed: (BuildContext context) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Select an Option'),
                        content: DropdownButtonFormField(
                          value: selectedValue,
                          items: ['1.0', '5.0', '10.0', '20.0']
                              .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedValue = newValue;
                              });
                            }
                          },
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Save'),
                            onPressed: () {
                              // Save the selected value.
                              // You can implement storage logic here.
                              global_radius = double.parse(selectedValue);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
