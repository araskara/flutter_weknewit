import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learningdart/authmanager.dart';
import 'dart:io' show HttpStatus;
import 'package:learningdart/createpoll.dart'
    as CreatePoll; // Import CreatePollScreen if needed
import 'package:learningdart/main.dart';
import 'package:provider/provider.dart';

class UsersListScore extends StatefulWidget {
  @override
  _UsersListScoreState createState() => _UsersListScoreState();
}

class _UsersListScoreState extends State<UsersListScore> {
  Future<List<Map<String, dynamic>>> fetchUsersByScore() async {
    final response = await http.get(
      Uri.parse('https://wk.up.railway.app/users/scores/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == HttpStatus.ok) {
      List<dynamic> users = json.decode(response.body);
      return List<Map<String, dynamic>>.from(users);
    } else {
      throw Exception('Failed to load users by score');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users by Score')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsersByScore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final user = snapshot.data![index];
                return ListTile(
                  title: Text(
                      user['username']), // adjust field name as per your model
                  trailing: Text('Score: ${user['score']}'),
                );
              },
            );
          } else {
            return Center(child: Text('No users found'));
          }
        },
      ),
    );
  }
}
