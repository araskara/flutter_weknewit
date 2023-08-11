import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learningdart/login.dart' as LoginScreen;
import 'package:learningdart/polls_screen.dart' as PollsScreen;
import 'package:learningdart/registration.dart' as RegistrationScreen;
import 'package:learningdart/authmanager.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key})
      : super(key: key); // Add this line for the const constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polls and Registration App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(
          isLoggedIn: false), // Pass isLoggedIn based on user authentication
    );
  }
}

class HomePage extends StatelessWidget {
  final bool
      isLoggedIn; // Add this variable to determine if the user is logged in
  final AuthManager authManager = AuthManager();
  HomePage({required this.isLoggedIn}); // Constructor to pass isLoggedIn value

  @override
  Widget build(BuildContext context) {
    String? authToken = authManager.authToken; // Fetch the token once
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('See Polls List'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => PollsScreen.PollsScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            // Conditionally show the appropriate button based on isLoggedIn
            if (authToken != null) // Show the button only if not logged in
              ElevatedButton(
                child: Text('Go to Registration'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) =>
                            RegistrationScreen.RegistrationScreen()),
                  );
                },
              ),
            if (authToken != null) // Show the button only if not logged in
              ElevatedButton(
                child: Text('Log In'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => LoginScreen.LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
