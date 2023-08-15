import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart'; // Import the AuthProvider class
import 'package:learningdart/login.dart' as LoginScreen;
import 'package:learningdart/registration.dart' as RegistrationScreen;
import 'package:learningdart/polls_screen.dart' as PollsScreen;
import 'package:learningdart/createpoll.dart' as CreatePoll;
import 'package:learningdart/logout.dart' as LogoutScreen;
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polls and Registration App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //if (isLoggedIn)
            ElevatedButton(
              child: Text('Logout'),
              onPressed: () {
                authProvider.logout();
                print('Logout button pressed');
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => LoginScreen.LoginScreen()),
                );
              },
            ),
            //if (isLoggedIn)
            ElevatedButton(
              child: Text('Create Poll '),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => CreatePoll.CreatePollScreen()),
                );
              },
            ),
            // if (isLoggedIn)
            ElevatedButton(
              child: Text('Poll List '),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => PollsScreen.PollsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    // Logic for logging in
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    // Logic for logging out
    _isLoggedIn = false;
    notifyListeners();
  }
}
