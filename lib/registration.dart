import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learningdart/login.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_utils.dart'; // Import the utility function
import 'package:learningdart/main.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _register() async {
    try {
      final response = await http.post(
        Uri.parse('https://wk.up.railway.app/dj-rest-auth/registration/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'email': _emailController.text,
          'password1': _passwordController.text,
          'password2': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 201 ||
          response.statusCode == 200 ||
          response.statusCode == 204) {
        // If registration is successful, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to Login Screen after a short delay to let the SnackBar show
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else {
        // If registration fails, handle the error response
        // Print response status code and body
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode != 201 ||
            response.statusCode != 200 ||
            response.statusCode != 204) {
          try {
            // Try to decode the error response body
            Map<String, dynamic> errorData = json.decode(response.body);
            if (errorData.containsKey('username')) {
              // If the error response contains a "username" key, show the corresponding error message
              String usernameErrorMessage = errorData['username'][0];
              showApiErrorAlert(
                  context, usernameErrorMessage); // Show the alert
            } else if (errorData.containsKey('email')) {
              // If the error response contains an "email" key, show the corresponding error message
              String emailErrorMessage = errorData['email'][0];
              showApiErrorAlert(context, emailErrorMessage); // Show the alert
            } else {
              // If the error response doesn't match known keys, show a generic error message
              showApiErrorAlert(context,
                  'An error occurred.'); // Show a generic error message
            }
          } catch (e) {
            // Handle any exception that occurs while parsing the response
            showApiErrorAlert(
                context, 'An error occurred.'); // Show a generic error message
          }
        }
      }
    } catch (e) {
      // Handle any exceptions that occur during the HTTP request
      showApiErrorAlert(
          context, 'An error occurred.'); // Show a generic error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registration')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  } else if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  } else if (value.length < 6) {
                    return 'Password should be at least 6 characters';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() == true) {
                    await _register();
                  }
                },
                child: Text('Register'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
