// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drug/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth.dart';

/// Displayed as a profile image if the user doesn't have one.
const placeholderImage =
    'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';

/// Profile page shows after sign in or registration.
class ProfilePage extends StatefulWidget {
  // ignore: public_member_api_docs
  const ProfilePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  State<ProfilePage> createState() => _ProfilePageState();
}

late User user;

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController controller;
  final phoneController = TextEditingController();
  final narcanController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();

  String? photoURL;

  bool showSaveButton = false;
  bool isLoading = false;
  String? gender;

  @override
  void initState() {
    user = auth.currentUser!;
    controller = TextEditingController(text: user.displayName);

    controller.addListener(_onNameChanged);

    auth.userChanges().listen((event) {
      if (event != null && mounted) {
        setState(() {
          user = event;
        });
      }
    });

    log(user.toString());

    super.initState();
    _getProfileData();
  }

  @override
  void dispose() {
    controller.removeListener(_onNameChanged);

    super.dispose();
  }

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  void _onNameChanged() {
    setState(() {
      if (controller.text == user.displayName || controller.text.isEmpty) {
        showSaveButton = false;
      } else {
        showSaveButton = true;
      }
    });
  }

  /// Map User provider data into a list of Provider Ids.
  List get userProviders => user.providerData.map((e) => e.providerId).toList();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              maxRadius: 60,
                              backgroundImage: NetworkImage(
                                user.photoURL ?? placeholderImage,
                              ),
                            ),
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              end: 0,
                              bottom: 0,
                              child: Material(
                                clipBehavior: Clip.antiAlias,
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(40),
                                child: InkWell(
                                  onTap: () async {
                                    // final photoURL = await getPhotoURLFromUser();

                                    // if (photoURL != null) {
                                    //   await user.updatePhotoURL(photoURL);
                                    // }
                                  },
                                  radius: 50,
                                  child: const SizedBox(
                                    width: 35,
                                    height: 35,
                                    child: Icon(Icons.edit),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          textAlign: TextAlign.center,
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            alignLabelWithHint: true,
                            label: Center(
                              child: Text(
                                'Click to add a display name',
                              ),
                            ),
                          ),
                        ),
                        Text(user.email ?? user.phoneNumber ?? 'User'),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (userProviders.contains('phone'))
                              const Icon(Icons.phone),
                            if (userProviders.contains('password'))
                              const Icon(Icons.mail),
                            if (userProviders.contains('google.com'))
                              SizedBox(
                                width: 24,
                                child: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone),
                            hintText: 'Bill',
                            labelText: 'First Name',
                          ),
                        ),
                        TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone),
                            hintText: 'Shake',
                            labelText: 'Last Name',
                          ),
                        ),
                        TextFormField(
                          controller: ageController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone),
                            hintText: '19',
                            labelText: 'Age',
                          ),
                        ),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.phone),
                            hintText: '+33612345678',
                            labelText: 'Phone number',
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: gender,
                          items: ["Male", "Female"]
                              .map((label) => DropdownMenuItem(
                                    child: Text(label.toString()),
                                    value: label,
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            hintText: 'Gender',
                            labelText: 'Gender',
                          ),
                          onChanged: (String? s) {
                            gender = s;
                          },
                        ),
                        const Divider(),
                        TextButton(
                          onPressed: _saveChanges,
                          child: const Text('Save Changes'),
                        ),
                        const Divider(),
                        TextButton(
                          onPressed: _signOut,
                          child: const Text('Sign out'),
                        ),
                        const Divider(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsPage()));
                          },
                          child: const Text('Back to Settings'),
                        )
                      ]),
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 40,
              top: 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !showSaveButton
                    ? SizedBox(key: UniqueKey())
                    : TextButton(
                        onPressed: isLoading ? null : updateDisplayName,
                        child: const Text('Save changes'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void> _saveChanges() async {
    final email = user.email;

    final existingDoc = await users.where('email', isEqualTo: email).get();

    if (existingDoc.docs.isNotEmpty) {
      // If a document with the same email exists, update it
      final docId = existingDoc.docs.first.id;

      users.doc(docId).set({
        'age': int.parse(ageController.text),
        'email': email,
        'firstName': firstNameController.text,
        'gender': gender,
        'lastName': lastNameController.text,
        'phoneNumber': phoneController.text,
        'narcan': narcanController.text,
      }).then((_) {
        print('Data updated in Firebase successfully');
      }).catchError((error) {
        print('Failed to update data in Firebase: $error');
      });
    } else {
      // If no document with the same email exists, create a new one
      users.add({
        'age': int.parse(ageController.text),
        'email': email,
        'firstName': firstNameController.text,
        'gender': gender,
        'lastName': lastNameController.text,
        'phoneNumber': phoneController.text,
        'narcanNumber': narcanController.text,
      }).then((_) {
        print('Data added to Firebase successfully');
      }).catchError((error) {
        print('Failed to add data to Firebase: $error');
      });
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MyApp()));
  }

  Future<void> _getProfileData() async {
    // Define a new child node under the database reference where you want to store the data.

    FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (user.email == doc['email']) {
          setState(() {
            ageController.text = (doc['age']).toString();
            firstNameController.text = doc['firstName'];
            phoneController.text = doc['phoneNumber'];
            narcanController.text = doc['narcan'];
            gender = doc['gender'];
            lastNameController.text = doc['lastName'];
          });

          // break;
        }
      });
    });
  }

  Future updateDisplayName() async {
    await user.updateDisplayName(controller.text);

    setState(() {
      showSaveButton = false;
    });

    // ignore: use_build_context_synchronously
    ScaffoldSnackbar.of(context).show('Name updated');
  }

  Future<String?> getPhotoURLFromUser() async {
    String? photoURL;

    // Update the UI - wait for the user to enter the SMS code
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('New image Url:'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
            OutlinedButton(
              onPressed: () {
                photoURL = null;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
          content: Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (value) {
                photoURL = value;
              },
              textAlign: TextAlign.center,
              autofocus: true,
            ),
          ),
        );
      },
    );

    return photoURL;
  }

  /// Example code for sign out.
  Future<void> _signOut() async {
    await auth.signOut();
    await GoogleSignIn().signOut();
  }
}
