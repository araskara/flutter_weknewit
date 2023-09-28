import 'package:dio/dio.dart';
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
  int userScore = 0;

  @override
  void initState() {
    super.initState();
    _userActivityFuture = fetchUserActivity();

    fetchUserScore().then((score) {
      setState(() {
        userScore = score;
      });
    }).catchError((error) {
      // Handle any errors here if needed
    });
  }

  Future<Map<String, dynamic>> fetchUserActivity() async {
    final authToken = authManager.authToken;

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

  Future<void> updatePoll(
      int pollId, String correctAnswer, String proofLink) async {
    final authToken = authManager.authToken;

    final response = await http.put(
      Uri.parse('https://wk.up.railway.app/polls/$pollId/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correct_answer': correctAnswer,
        'proof_link': proofLink,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update the poll');
    }
  }

  Future<void> createObjection(
      int pollId, int voteId, String reason, String proofLink) async {
    final authToken = authManager.authToken;
    final url = Uri.parse('https://wk.up.railway.app/objection/objections/');
    final headers = {
      'Authorization': 'Token $authToken',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'poll': pollId,
      'vote': voteId,
      'reason': reason,
      'proof_link': proofLink,
    });

    print('Sending request to $url with body: $body and headers: $headers');

    final response = await http.post(url, headers: headers, body: body);

    print(
        'Received response with status code: ${response.statusCode} and body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Failed to create objection');
    }
  }

  Future<int> fetchUserScore() async {
    final authToken = authManager.authToken;

    final response = await http.get(
      Uri.parse('https://wk.up.railway.app/user/score/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      int score = json.decode(response.body)['score'] ?? 0;
      return score;
    } else {
      throw Exception('Failed to load user score');
    }
  }

  void showUpdateDialog(int pollId) {
    String correctAnswer = 'yes'; // default value set to 'yes'
    String proofLink = '';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Poll'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  items: ["yes", "no"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    correctAnswer = value!;
                  },
                  decoration: InputDecoration(labelText: 'Correct Answer'),
                  value: correctAnswer,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Proof Link'),
                  onChanged: (value) {
                    proofLink = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () async {
                try {
                  await updatePoll(pollId, correctAnswer, proofLink);
                  setState(() {
                    _userActivityFuture = fetchUserActivity();
                  });
                  Navigator.of(context).pop();
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update poll')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Center(child: Text('Score: $userScore')),
            ),
          ],
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
                  ListView(
                    children: snapshot.data!['polls'].map<Widget>((poll) {
                      return ListTile(
                        title: Text(poll['question']),
                        subtitle: Text(
                            'Yes: ${poll['yes_percentage']}%, No: ${poll['no_percentage']}%'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                showUpdateDialog(poll['id']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                try {
                                  await deletePoll(poll['id']);
                                  setState(() {
                                    _userActivityFuture = fetchUserActivity();
                                  });
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Failed to delete poll')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  ListView(
                    children: snapshot.data!['votes'].map<Widget>((vote) {
                      return ListTile(
                        title:
                            Text('Vote for Poll: ${vote['poll']['question']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Choice: ${vote['choice']}'),
                            if (vote['proof_link'] != null)
                              Text('Proof: ${vote['proof_link']}'),
                          ],
                        ),
                        trailing:
                            vote['choice'] != vote['poll']['correct_answer']
                                ? IconButton(
                                    icon: Icon(Icons.error_outline),
                                    onPressed: () {
                                      showObjectionDialog(
                                          vote['poll']['id'], vote['id']);
                                    },
                                  )
                                : null,
                      );
                    }).toList(),
                  ),
                ],
              );
            } else {
              return Center(child: Text('No activity found'));
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePoll.CreatePollScreen(),
              ),
            );
          },
          tooltip: 'Create Poll',
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void showObjectionDialog(int pollId, int voteId) {
    final _formKey = GlobalKey<FormState>();
    String reason = '';
    String proofLink = '';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Raise Objection'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Reason'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      reason = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Proof Link'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a proof link';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      proofLink = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await createObjection(pollId, voteId, reason, proofLink);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Objection raised successfully')),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to raise objection')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
