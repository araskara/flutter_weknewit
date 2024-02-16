import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:learningdart/authmanager.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    initFirebaseMessaging();
    requestPermission();
    getTokenAndSendToServer();
  }

  void initFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received: ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened a notification: ${message.notification?.body}");
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            "Opened a terminated notification: ${message.notification?.body}");
      }
    });
  }

  void requestPermission() {
    _firebaseMessaging.requestPermission();
  }

  Future<void> getTokenAndSendToServer() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FirebaseMessaging token: $token");
      await _sendTokenToServer(token);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    final authToken = authManager.authToken;

    final response = await http.post(
      Uri.parse('https://wk.up.railway.app/notifications/store_fcm_token/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: '{"fcm_token": "$token"}',
    );

    if (response.statusCode == 200) {
      print('Token sent to server successfully');
    } else {
      print('Failed to send token to server: ${response.body}');
      print('Response status code: ${response.statusCode}');
      print('Redirection URL: ${response.headers['location']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                      child: Text(
                    "Firebase Messaging",
                    style: TextStyle(fontSize: 40),
                  )),
                  SizedBox(height: 20),
                  Center(
                      child: Text(
                    "How to integrate Firebase Messaging",
                    style: TextStyle(fontSize: 18),
                  ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
