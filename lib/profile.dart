import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learningdart/authmanager.dart';
import 'dart:io' show HttpStatus;
import 'package:learningdart/createpoll.dart'
    as CreatePoll; // Import CreatePollScreen if needed
import 'package:learningdart/main.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<Map<String, dynamic>>? _userActivityFuture;
  final authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    _userActivityFuture = fetchUserActivity();
  }

  Future<Map<String, dynamic>> fetchUserActivity() async {
    final authToken = authManager.authToken; // Get token from your AuthManager

    final response = await http.get(
      Uri.parse('https://wk.up.railway.app/polls/user_activity/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user activity');
    }
  }

  Future<void> deletePoll(int pollId) async {
    final authToken = authManager.authToken;

    final response = await http.delete(
      Uri.parse('https://wk.up.railway.app/polls/$pollId/delete/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != HttpStatus.noContent) {
      throw Exception('Failed to delete the poll');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Activity'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'My Polls'),
              Tab(text: 'My Votes'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _userActivityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              return TabBarView(
                children: [
                  // My Polls
                  ListView(
                    children: [
                      ...snapshot.data!['polls']
                          .map((poll) => ListTile(
                                title: Text(poll['question']),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    try {
                                      await deletePoll(poll['id']);
                                      // Refresh the user activity after deletion
                                      setState(() {
                                        _userActivityFuture =
                                            fetchUserActivity();
                                      });
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Failed to delete poll')),
                                      );
                                    }
                                  },
                                ),
                              ))
                          .toList(), // Convert map to list
                    ],
                  ),
                  // My Votes
                  ListView(
                    children: [
                      ...snapshot.data!['votes']
                          .map((vote) => ListTile(
                                title:
                                    Text('Vote for Poll: ${vote['poll_text']}'),
                                subtitle: Text('Choice: ${vote['choice']}'),
                              ))
                          .toList(), // Convert map to list
                    ],
                  ),
                ],
              );
            } else {
              return Center(child: Text('No activity found'));
            }
          },
        ),
      ),
    );
  }
}
