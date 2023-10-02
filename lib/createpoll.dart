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
  String _category = '';
  List<String> _categories = [
    'Politics',
    'Economy',
    'Sport',
    'Science',
    'Art',
    'others'
  ]; // add more as needed
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
          'category': _category,
          //'reference_link': _referenceLink,
          //'proof_link': _proofLink,
          'poll_deadline': _pollDeadline.toIso8601String(),
          'vote_deadline': _voteDeadline.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        // Poll created successfullyv
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
              DropdownButtonFormField<String>(
                value: _category.isEmpty ? null : _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a category.';
                  }
                  return null;
                },
              ),
              /*TextFormField(
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
              ), */
              ElevatedButton(
                child: Text(_voteDeadline == null
                    ? 'Pick Vote Deadline'
                    : 'Vote Deadline: ${DateFormat.yMd().add_jm().format(_voteDeadline)}'), // Edited to show time
                onPressed: () async {
                  final datePicked = await showDatePicker(
                    context: context,
                    initialDate: _voteDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (datePicked != null) {
                    final timePicked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_voteDeadline),
                    );
                    if (timePicked != null) {
                      final DateTime combinedDateTime = DateTime(
                        datePicked.year,
                        datePicked.month,
                        datePicked.day,
                        timePicked.hour,
                        timePicked.minute,
                      );
                      setState(() {
                        _voteDeadline = combinedDateTime;
                      });
                    }
                  }
                },
              ),
              ElevatedButton(
                child: Text(_pollDeadline == null
                    ? 'Pick Poll Deadline'
                    : 'Poll Deadline: ${DateFormat.yMd().add_jm().format(_pollDeadline)}'),
                onPressed: () async {
                  final datePicked = await showDatePicker(
                    context: context,
                    initialDate: _pollDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (datePicked != null) {
                    final timePicked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_pollDeadline),
                    );
                    if (timePicked != null) {
                      final DateTime combinedDateTime = DateTime(
                        datePicked.year,
                        datePicked.month,
                        datePicked.day,
                        timePicked.hour,
                        timePicked.minute,
                      );
                      setState(() {
                        _pollDeadline = combinedDateTime;
                      });
                    }
                  }
                },
              ),
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
