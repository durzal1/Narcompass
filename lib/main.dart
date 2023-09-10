import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drug/notis.dart';
import 'package:drug/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math';
import 'package:twilio_flutter/twilio_flutter.dart';

// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth.dart';
import 'firebase_options.dart';
import 'profile.dart';

Future<void> addUserEmailToFirestore(String email) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference narcanCollection = firestore.collection('narcan');

  final existingDoc =
      await narcanCollection.where('email', isEqualTo: email).get();

  if (existingDoc.docs.isNotEmpty) {
    // If a document with the same email exists, update it
    final docId = existingDoc.docs.first.id;

    narcanCollection.doc(docId).set({'email': email, 'accepted': ''}).then((_) {
      print('Data updated in Firebase successfully');
    }).catchError((error) {
      print('Failed to update data in Firebase: $error');
    });
  } else {
    // If no document with the same email exists, create a new one
    narcanCollection.add({'email': email, 'accepted': ''}).then((_) {
      print('Data added to Firebase successfully');
    }).catchError((error) {
      print('Failed to add data to Firebase: $error');
    });
  }
}

String person_email = '';

bool help_sent = false;

// /// Requires that a Firebase local emulator is running locally.
// /// See https://firebase.flutter.dev/docs/auth/start/#optional-prototype-and-test-with-firebase-local-emulator-suite
bool shouldUseFirebaseEmulator = false;
TravelMode travelmode = TravelMode.driving;
late FirebaseApp app;
late FirebaseAuth auth;
var global_radius = 1000.0;
Map<String, MapEntry<LatLng, double>> emails = {};

// Requires that the Firebase Auth emulator is running locally
// e.g via `melos run firebase:emulator`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We're using the manual installation on non-web plastforms since Google sign in plugin doesn't yet support Dart initialization.
  // See related issue: https://github.com/flutter/flutter/issues/96391

  // We store the app and auth to make testing with a named instance easier.
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  auth = FirebaseAuth.instanceFor(app: app);

  if (shouldUseFirebaseEmulator) {
    await auth.useAuthEmulator('localhost', 9099);
  }

  runApp(const AuthExampleApp());
}

final ThemeData narcanTheme = ThemeData(
  primaryColor: Color(0xFF2979FF), // A shade of blue
  backgroundColor: Color(0xFFF5F5F5), // Light gray background
  scaffoldBackgroundColor: Colors.white, // White scaffold background

  textTheme: TextTheme(
    // Define text styles for your app
    headline6: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
    bodyText2: TextStyle(
      fontSize: 16.0,
      color: Colors.black87,
    ),
  ),
);

/// The entry point of the application.
///
/// Returns a [MaterialApp].
class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Example App',
      theme: narcanTheme,
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Visibility(
                  visible: constraints.maxWidth >= 1200,
                  child: Expanded(
                    child: Container(
                      height: double.infinity,
                      color: Theme.of(context).colorScheme.primary,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Firebase Auth Desktop',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 1200
                      ? constraints.maxWidth / 2
                      : constraints.maxWidth,
                  child: StreamBuilder<User?>(
                    stream: auth.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return const ProfilePage();
                      }
                      return const AuthGate();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class AnimatedHelpButton extends StatefulWidget {
  AnimatedHelpButton(String email, {super.key}) {}

  @override
  // ignore: no_logic_in_create_state
  State<AnimatedHelpButton> createState() => AnimatedHelpButtonState();
}

bool lifeRaftVisibility = true;

class AnimatedHelpButtonState extends State<AnimatedHelpButton> {
  double _width = -1;

  double _height = -1;
  final BorderRadiusGeometry _borderRadius = BorderRadius.circular(8);

  String email_need = '';

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (person_email != '') {
      lifeRaftVisibility = false;
      _height = -1;
      _width = -1;

      return AnimatedContainer(
        height: _height == -1
            ? MediaQuery.of(context).size.height * .3333
            : _height,
        width: _width == -1 ? MediaQuery.of(context).size.width : _width,
        duration: const Duration(seconds: 1),
        color: Colors.blue,
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.only(left: 40),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: FutureBuilder(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }

                      // Assuming you have the person.key
                      var userDoc = snapshot.data?.docs.firstWhere(
                        (doc) => doc['email'] == person_email,
                      );

                      if (userDoc == null) {
                        return Text("User not found");
                      }

                      var age = userDoc['age'].toString();
                      var firstName = userDoc['firstName'];
                      var phoneNumber = userDoc['phoneNumber'];
                      var lastName = userDoc['lastName'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help needed',
                            style: TextStyle(fontSize: 30, color: Colors.white),
                            // color: Colors.white,
                          ),
                          Text(
                            'Age:          $age',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Text(
                            'First Name:   $firstName',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Text(
                            'Phone Number: $phoneNumber',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Text(
                            'Last Name:    $lastName',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ],
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: TextButton.styleFrom(
                          onSurface: Colors.grey,
                          shadowColor: Colors.grey,
                          elevation: 5,
                          minimumSize:
                              Size(screenWidth * 0.5, screenHeight * 0.33)),
                      onPressed: () async {
                        // Implement your Confirm button action here
                        String userEmail = user.email!;
                        CollectionReference narcan =
                            FirebaseFirestore.instance.collection('narcan');

                        var res = await narcan
                            .where('email', isEqualTo: person_email)
                            .get();
                        final docId = res.docs.first.id;

                        narcan.doc(docId).set({
                          'email': person_email,
                          'accepted': user.email
                        }).then((_) {
                          print('Data updated in Firebase successfully');
                        }).catchError((error) {
                          print('Failed to update data in Firebase: $error');
                        });
                        setState(() {
                          lifeRaftVisibility = true; // Minimize the container
                          _height = screenHeight * .1;
                          person_email = '';
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: Text(
                                        "The person you are responding to has been alerted that you are on your way."));
                              });
                        });
                      },
                      child: Text('Confirm'),
                    ),
                    ElevatedButton(
                      style: TextButton.styleFrom(
                        onSurface: Colors.grey,
                        shadowColor: Colors.grey,
                        elevation: 5,
                        minimumSize:
                            Size((screenWidth * 0.5) - 32, screenHeight * 0.33),
                      ),
                      onPressed: () {
                        setState(() {
                          lifeRaftVisibility = true;
                          _height = screenHeight * .1;
                        });
                        // Implement your Cancel button action here
                        // Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    // TODO: implement build
    return AnimatedContainer(
        height:
            _height == -1 ? MediaQuery.of(context).size.height * .1 : _height,
        width: _width == -1 ? MediaQuery.of(context).size.width : _width,
        duration: const Duration(seconds: 1),
        color: Color.fromARGB(255, 0, 142, 250),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.only(left: 40),
        child: lifeRaftVisibility
            ? IconButton(
                iconSize: 100,
                icon: const Icon(Icons.support),
                onPressed: () {
                  lifeRaftVisibility = false;
                  setState(() {
                    _height = screenHeight * .3333;
                    _width = screenWidth;
                  });
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "I Need Help",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 200, // Adjust the height as needed
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 0.0,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: TextButton.styleFrom(
                              onSurface: Colors.grey,
                              shadowColor: Colors.grey,
                              elevation: 5,
                              minimumSize: Size((screenWidth * 0.5) - 32,
                                  screenHeight * 0.33),
                            ),
                            onPressed: () async {
                              // Implement your Confirm button action here
                              // For example, you can add code to confirm an action.
                              String userEmail = user.email!;
                              if (userEmail != null && userEmail.isNotEmpty) {
                                addUserEmailToFirestore(userEmail);
                              }

                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text(
                                            "Your request for help has been recieved! Someone will be on their way shortly to help you."));
                                  });

                              setState(() {
                                lifeRaftVisibility =
                                    true; // Minimize the container
                                _height = screenHeight * .1;
                                help_sent = true;
                              });
                            },
                            child: Text('Confirm'),
                          ),
                          ElevatedButton(
                            style: TextButton.styleFrom(
                              onSurface: Colors.grey,
                              shadowColor: Colors.grey,
                              elevation: 5,
                              minimumSize: Size((screenWidth * 0.5) - 32,
                                  screenHeight * 0.33),
                            ),
                            onPressed: () {
                              setState(() {
                                lifeRaftVisibility = true;
                                _height = screenHeight * .1;
                              });

                              // Implement your Cancel button action here
                              // For example, you can add code to cancel an action.
                              // Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ), // Replace Spacer with your widget
                  SizedBox(height: 20), // Add some spacing
                ],
              ));
  }
}

class MapSampleState extends State<MapSample> {
  GoogleMapController? mapController; //contrller for Google map
  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPiKey = "-";

  Set<Marker> markers = Set(); //markers for google map
  Map<PolylineId, Polyline> polylines = {}; //polylines to show direction
  //I DUNNO WHAT I'M DOING SEND HELP.
  double latitude = 0;
  double longitude = 0;

  LatLng startLocation = LatLng(0, 0);
  LatLng endLocation = LatLng(0, 0);
  double distance = 0.0;

  LatLng? _currentPosition;
  bool _isLoading = true;
  Timer? locationTimer;
  Timer? narcanTimer;

  @override
  void initState() {
    super.initState();
    getLocation();
    startLocationUpdates();
    startHelperUpdates();
    //getDirections(); //fetch direction polylines from Google API
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey,
      PointLatLng(latitude, longitude),
      PointLatLng(endLocation.latitude, endLocation.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    //polulineCoordinates is the List of longitute and latidtude.
    double totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    print(totalDistance);

    setState(() {
      distance = totalDistance;
    });

    //add to the list of poly line coordinates
    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.deepPurpleAccent,
      points: polylineCoordinates,
      width: 8,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  final locationUpdateInterval =
      Duration(seconds: 10); // Update location every 10 seconds

  Future<void> _alertHelp(
      MapEntry<String, MapEntry<LatLng, double>> person) async {
    CollectionReference narcan =
        FirebaseFirestore.instance.collection('narcan');

    var res = await narcan.where('email', isEqualTo: person.key).get();

    final docId = res.docs.first.id;
    final docData = res.docs.first.data() as Map<String, dynamic>;
    String accepted = docData['accepted'];
    String help = docData['email'];

    var res1 = await narcan.where('accepted', isEqualTo: user.email).get();

    if (accepted != '' || res1.docs.length > 0) {
      return;
    }

    endLocation = LatLng(person.value.key.latitude.toDouble(),
        person.value.key.longitude.toDouble());
    startLocation = LatLng(latitude, longitude);
    getDirections();

    setState(() async {
      person_email = person.key;
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      var res = await users.where('email', isEqualTo: person.key).get();
      person_name = res.docs.first['firstName'];
    });

    // Call _GetInfo to retrieve personal information
  }

  void _alertHelpOnTheWay() async {
    CollectionReference narcan =
        FirebaseFirestore.instance.collection('narcan');
    var res = await narcan.where('email', isEqualTo: user.email).get();

    final docId = res.docs.first.id;
    final docData = res.docs.first.data() as Map<String, dynamic>;
    String accepted = docData['accepted'];

    CollectionReference ref = FirebaseFirestore.instance.collection('text');

    var r = await ref.where('email', isEqualTo: user.email).get();

    CollectionReference loc = FirebaseFirestore.instance.collection('location');

    if (r.docs.isNotEmpty) {
      var dt = r.docs.first.data() as Map<String, dynamic>;
      if (dt['var'] == 'y') return;
    }
    if (accepted == '' || (latitude + longitude == 0.0)) {
      return;
    }

    var l = await loc.where('email', isEqualTo: accepted).get();
    var m = l.docs.first;
    var kk = LatLng(m['latitude'], m['longitude']);
    endLocation = kk;
    double d = await getDistance(kk);

    getDirections();

    if (d == -1) d = 0;
    FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        if (user.email == doc['email']) {
          String phone = doc['phoneNumber'];

          CollectionReference users =
              FirebaseFirestore.instance.collection('users');

          var helper = await users.where('email', isEqualTo: accepted).get();

          if (r.docs.isNotEmpty && d < 5.0) {
            ref.doc(r.docs.first.id).set({'email': user.email, 'var': 'z'});
          } else if (d < 5.0 && r.docs.isEmpty) {
            sendMessage(
                phone,
                helper.docs.first['firstName'] +
                    " is helping! They are $d km away!");
            ref.add({'email': user.email, 'var': 'n'});
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text(helper.docs.first['firstName'] +
                        " is helping! They are $d km away!"));
              },
            );
          } else if (r.docs.isEmpty) {
            ref.add({'email': user.email, 'var': 'n'});
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text(phone + " is helping! They are $d km away!"));
              },
            );
          }
        }
      });
    });
  }

  void startHelperUpdates() async {
    narcanTimer = Timer.periodic(locationUpdateInterval, (timer) async {
      _alertHelpOnTheWay();

      var value = getAllUserLocations(global_radius);

      if (emails.length > 0) {
        var l = emails.entries.toList();
        l.sort((a, b) => a.value.value.compareTo(b.value.value));
        _alertHelp(l.first);
      }
    });
  }

  void startLocationUpdates() async {
    locationTimer = Timer.periodic(locationUpdateInterval, (timer) async {
      LocationPermission permission;
      permission = await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        _isLoading = false;
        updateLocationDatabase();
      });

      // Optionally, you can move the camera to the updated location
      mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    });
  }

  getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double long = position.longitude;
    latitude = lat;
    longitude = long;
    LatLng location = LatLng(lat, long);

    setState(() {
      _currentPosition = location;
      _isLoading = false;
    });
  }

  CollectionReference locDB = FirebaseFirestore.instance.collection('location');

  Future<double> getDistance(LatLng endlocation) async {
    PolylineResult result;
    try {
      result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(latitude, longitude),
        PointLatLng(endLocation.latitude, endLocation.longitude),
        travelMode: TravelMode.driving,
      );
    } catch (error) {
      print(error);
      return -1;
    }

    List<LatLng> polylineCoordinates = [];

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    //polulineCoordinates is the List of longitute and latidtude.
    double totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    // double eLatitude = endlocation.latitude;
    // double eLongitude = endlocation.longitude;
    // showDialog(
    //     context: context,
    //     builder: ((context) => AlertDialog(
    //         title: Text("fick"),
    //         content: Text(
    //             "The distance between ($latitude, $longitude) and ($eLatitude, $eLongitude) is ($totalDistance) kilometers."))));

    return totalDistance;
  }

  void getAllUserLocations(double radius) {
    FirebaseFirestore.instance
        .collection('narcan')
        .get()
        .then((QuerySnapshot narcSnap) {
      FirebaseFirestore.instance
          .collection('location')
          .get()
          .then((QuerySnapshot locSnap) {
        locSnap.docs.forEach((doc) {
          narcSnap.docs.forEach((narc) {
            if (doc['email'] == narc['email'] && doc['email'] != user.email) {
              getDistance(LatLng(doc['latitude'], doc['longitude']))
                  .then((value) {
                if (value <= radius) {
                  emails[doc['email']] = MapEntry(
                      LatLng(doc['latitude'], doc['longitude']), value);

                  // showDialog(
                  //     context: context,
                  //     builder: ((context) => AlertDialog(
                  //         title: Text("fick"),
                  //         content: Text(emails.toString()))));
                }
              });
            }
          });
        });
      });
    });
  }

  void updateLocationDatabase() async {
    final email = user.email;

    final existingDoc = await locDB.where('email', isEqualTo: email).get();

    if (existingDoc.docs.isNotEmpty) {
      // If a document with the same email exists, update it
      final docId = existingDoc.docs.first.id;

      locDB.doc(docId).set({
        'email': user.email,
        'latitude': latitude,
        'longitude': longitude
      }).then((_) {
        print('Data updated in Firebase successfully');
      }).catchError((error) {
        print('Failed to update data in Firebase: $error');
      });
    } else {
      locDB.add(
          {'email': user.email, 'latitude': latitude, 'longitude': longitude});
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String name = 'Map';
  String person_name = '';

  @override
  Widget build(BuildContext context) {
    String dd = distance.toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
          title: Text(help_sent
              ? 'Help is $dd km away'
              : (person_name != '' ? '$person_name is $dd km away' : name)),
          actions: <Widget>[
            IconButton(
              padding: EdgeInsets.only(left: 25.0),
              icon: Icon(Icons.settings),
              iconSize: 50,
              color: Colors.black,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              ),
            ),
          ]),
      floatingActionButton: AnimatedHelpButton(
        person_email,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 16.0,
                  ),
                  markers: <Marker>{
                    Marker(
                      //add distination location marker
                      markerId: MarkerId(endLocation.toString()),
                      position: endLocation, //position of marker
                      infoWindow: InfoWindow(
                        //popup info
                        title: ' Needs Help! ',
                        snippet: 'Go here!',
                      ),
                      onTap: () {
                        CameraUpdate.newLatLng(LatLng(
                            endLocation.latitude, endLocation.longitude));
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          123), //Icon for Marker
                    ),
                    Marker(
                      //add start location marker
                      markerId:
                          MarkerId(LatLng(latitude, longitude).toString()),
                      position:
                          LatLng(latitude, longitude), //position of marker
                      infoWindow: InfoWindow(
                        //popup infoA
                        title: 'You are here! ',
                        snippet: 'Path start here',
                      ),
                      onTap: () {
                        CameraUpdate.newLatLng(LatLng(latitude, longitude));
                      },
                      icon: BitmapDescriptor.defaultMarker, //Icon for Marker
                    ),
                  }, //markers to show on map
                  polylines: Set<Polyline>.of(polylines.values), //polylines
                ),

                // Positioned(
                //   top: 32.0, // Adjust the position as needed
                //   left: 132.0, // Adjust the position as needed
                //   child: IconButton(
                //     icon: const Icon(Icons.settings),
                //     iconSize: 72,
                //     tooltip: "Settings",
                //     onPressed: () {
                //       Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //               builder: (context) => SettingsPage()));
                //     },
                //     style: ElevatedButton.styleFrom(
                //       primary: Colors.amber,
                //       onPrimary: Colors.white,
                //     ),
                //   ),
                // ),
                // Positioned(
                //   top: 16,
                //   left: 20,
                //   child: const AnimatedHelpButton(),
                // ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel(); // Cancel the timer when the widget is disposed.
    narcanTimer?.cancel(); // Cancel the timer when the widget is disposed.

    super.dispose();
  }
}
