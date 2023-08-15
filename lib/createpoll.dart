import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // for date formatting
import 'package:learningdart/authmanager.dart';

class CreatePollScreen extends StatefulWidget {
  @override
  _CreatePollScreenState createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  bool _isLoggedIn = false;
  final _formKey = GlobalKey<FormState>();
  final AuthManager authManager = AuthManager();

  String _question = '';
  DateTime _voteDeadline = DateTime.now();
  DateTime _pollDeadline = DateTime.now().add(Duration(days: 1));
  String _referenceLink = '';
  String _proofLink = '';

  void _checkUserAuthentication() {
    String? token = authManager.authToken;
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authToken = authManager.authToken;

      final response = await http.post(
        Uri.parse('https://wk.up.railway.app/polls/create/'),
        headers: {
          'Authorization': 'Token $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': _question,
          'reference_link': _referenceLink,
          'proof_link': _proofLink,
          'poll_deadline': _pollDeadline.toIso8601String(),
          'vote_deadline': _voteDeadline.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        // Poll created successfully
        Navigator.of(context).pop();
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating poll.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Poll')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Question'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a question.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _question = value!;
                },
              ),
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'Reference Link (optional)'),
                onSaved: (value) {
                  _referenceLink = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Proof Link (optional)'),
                onSaved: (value) {
                  _proofLink = value!;
                },
              ),

              ElevatedButton(
                child: Text(_voteDeadline == null
                    ? 'Pick Vote Deadline'
                    : 'Vote Deadline: ${DateFormat.yMd().format(_voteDeadline)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _voteDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null && picked != _voteDeadline) {
                    setState(() {
                      _voteDeadline = picked;
                    });
                  }
                },
              ),
              ElevatedButton(
                child: Text(_pollDeadline == null
                    ? 'Pick Poll Deadlin'
                    : 'Poll Deadline: ${DateFormat.yMd().format(_pollDeadline)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _voteDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null && picked != _pollDeadline) {
                    setState(() {
                      _pollDeadline = picked;
                    });
                  }
                },
              ),
              // Similarly add for _pollDeadline
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Create Poll'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
