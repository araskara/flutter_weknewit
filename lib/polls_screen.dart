import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learningdart/authmanager.dart';

class PollsScreen extends StatefulWidget {
  @override
  _PollsScreenState createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  late Future<List<Poll>> _pollsFuture;
  bool _isLoggedIn = false; // Track user's login status
  final AuthManager authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    _pollsFuture = fetchPolls();
    _checkUserAuthentication();
  }

  void _checkUserAuthentication() {
    String? token = authManager.authToken;
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<List<Poll>> fetchPolls() async {
    final response =
        await http.get(Uri.parse('https://wk.up.railway.app/polls/'));

    if (response.statusCode == 200) {
      Iterable jsonResponse = json.decode(response.body);
      return jsonResponse.map((poll) => Poll.fromJson(poll)).toList();
    } else {
      throw Exception('Failed to load polls');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? authToken = authManager.authToken; // Fetch the token once
    return Scaffold(
      appBar: AppBar(
        title: Text('Polls List'),
      ),
      body: FutureBuilder<List<Poll>>(
        future: _pollsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No polls found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final poll = snapshot.data![index];
                return ListTile(
                  title: Text(poll.question),
                  subtitle: Text('Vote Deadline: ${poll.voteDeadline}'),
                  trailing: SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PollDetailsScreen(poll: poll),
                          ),
                        );
                      },
                      child: Text('View Details'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Poll {
  final int id;
  final String question;
  final String voteDeadline;
  final String pollDeadline;
  final String correctAnswer;
  final String? proofLink;

  Poll({
    required this.id,
    required this.question,
    required this.voteDeadline,
    required this.pollDeadline,
    required this.correctAnswer,
    this.proofLink,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      question: json['question'],
      voteDeadline: json['vote_deadline'],
      pollDeadline: json['poll_deadline'],
      correctAnswer: json['correct_answer'],
      proofLink: json['proof_link'],
    );
  }
}

class PollDetailsScreen extends StatefulWidget {
  final Poll poll;

  PollDetailsScreen({required this.poll});

  @override
  _PollDetailsScreenState createState() => _PollDetailsScreenState();
}

class _PollDetailsScreenState extends State<PollDetailsScreen> {
  final authManager = AuthManager();
  String? _voteChoice;

  Future<void> _voteAsync(String choice) async {
    final authToken = authManager.authToken;

    if (authToken != null) {
      try {
        final response = await http.post(
          Uri.parse('https://wk.up.railway.app/polls/${widget.poll.id}/vote/'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'voted_yes': choice == 'Yes'}),
        );

        if (response.statusCode == 201) {
          setState(() {
            _voteChoice = choice;
          });
        } else {
          // Handle error response
        }
      } catch (e) {
        // Handle exception
      }
    } else {
      // Handle no auth token scenario
    }
  }

  @override
  Widget build(BuildContext context) {
    String? authToken = authManager.authToken; // Fetch the token once
    return Scaffold(
      appBar: AppBar(
        title: Text('Poll Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question: ${widget.poll.question}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Vote Deadline: ${widget.poll.voteDeadline}'),
              SizedBox(height: 10),
              Text('Poll Deadline: ${widget.poll.pollDeadline}'),
              SizedBox(height: 10),
              if (authToken != null)
                Text('Correct Answer: ${widget.poll.correctAnswer}'),
              SizedBox(height: 20),
              if (widget.poll.proofLink != null)
                Text('Proof Link: ${widget.poll.proofLink!}'),
              SizedBox(height: 20),
              if (authToken != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(hintColor: Colors.black),
                  child: RadioListTile<String>(
                    title: Text('Yes'),
                    value: 'Yes',
                    groupValue: _voteChoice,
                    onChanged: (value) async {
                      setState(() {
                        _voteChoice = value;
                      });
                      await _voteAsync(value!);
                    },
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(hintColor: Colors.black),
                  child: RadioListTile<String>(
                    title: Text('No'),
                    value: 'No',
                    groupValue: _voteChoice,
                    onChanged: (value) async {
                      setState(() {
                        _voteChoice = value;
                      });
                      await _voteAsync(value!);
                    },
                  ),
                ),
                SizedBox(height: 10), // Provide a bit of space
                ElevatedButton(
                  onPressed: () {
                    // Handle the button press
                  },
                  child: Text('Submit Vote'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Vote {
  final int id;
  final int user;
  final int poll;
  final bool
      votedYes; // Add this field to indicate whether the user voted Yes or No

  Vote({
    required this.id,
    required this.user,
    required this.poll,
    required this.votedYes,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      user: json['user'],
      poll: json['poll'],
      votedYes: json['voted_yes'],
    );
  }
}
