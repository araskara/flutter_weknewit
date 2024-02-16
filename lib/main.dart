import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart'; // Import the AuthProvider class
import 'package:learningdart/login.dart' as LoginScreen;
import 'package:learningdart/registration.dart' as RegistrationScreen;
import 'package:learningdart/polls_screen.dart' as PollsScreen;
import 'package:learningdart/createpoll.dart' as CreatePoll;
import 'package:learningdart/logout.dart' as LogoutScreen;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('de'), //German
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoggedIn) {
            return PollsScreen
                .PollsScreen(); // Navigate to PollsScreen if logged in
          } else {
            return HomePage();
          }
        },
      ),
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
            ElevatedButton(
              child: Text('Login'), // Change button label
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen.LoginScreen(),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: Text('Registration'), // Change button label
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        RegistrationScreen.RegistrationScreen(),
                  ),
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
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() async {
    // Logic for logging in
    _isLoggedIn = true;

    // Get the token for this device and send it to the backend
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FirebaseMessaging token: $token");
      // Send this token to the Django backend
      _sendTokenToServer(token);
    }

    notifyListeners();
  }

  Future<void> _sendTokenToServer(String token) async {
    final response = await http.post(
      Uri.parse('https://wk.up.railway.app/notifications/store_fcm_token/'),
      headers: {
        'Content-Type': 'application/json',
        // Add any other headers if needed (like authentication headers)
      },
      body: '{"fcm_token": "$token"}',
    );

    if (response.statusCode == 200) {
      print('Token sent to server successfully');
    } else {
      print('Failed to send token to server: ${response.body}');
    }
  }

  void logout() {
    // Logic for logging out
    _isLoggedIn = false;
    notifyListeners();
  }
}
