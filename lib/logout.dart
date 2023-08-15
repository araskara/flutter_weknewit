import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learningdart/main.dart'; // Import the HomePage class

class LogoutScreen extends StatelessWidget {
  Future<void> _handleLogout(BuildContext context) async {
    // Send a request to Django to logout
    final response = await http
        .post(Uri.parse('https://wk.up.railway.app/dj-rest-auth/logout/'));

    if (response.statusCode == 200) {
      // Handle successful logout. For instance, clear local authentication data.
      // Navigate user to the home page and remove all other screens from the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (Route<dynamic> route) => false,
      );
    } else {
      // Handle error. Display an alert or snackbar with error message.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error logging out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logout')),
      body: Center(
        child: ElevatedButton(
          child: Text('Logout'),
          onPressed: () => _handleLogout(context),
        ),
      ),
    );
  }
}
