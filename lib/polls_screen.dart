import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learningdart/authmanager.dart';
import 'dart:io' show HttpStatus;
import 'package:learningdart/createpoll.dart' as CreatePoll;
import 'package:learningdart/main.dart';
import 'package:provider/provider.dart';
import 'package:learningdart/profile.dart';
import 'package:learningdart/scoreslist.dart';
import 'package:fl_chart/fl_chart.dart';

enum VoteChoice { YES, NO }

String voteChoiceToString(VoteChoice choice) {
  switch (choice) {
    case VoteChoice.YES:
      return "yes";
    case VoteChoice.NO:
      return "no";
    default:
      throw ArgumentError('Unknown VoteChoice: $choice');
  }
}

class PollsScreen extends StatefulWidget {
  @override
  _PollsScreenState createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  late Future<List<Poll>> _pollsFuture;

  @override
  void initState() {
    super.initState();
    _pollsFuture = fetchPolls();
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

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Polls List'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: _logout,
            ),
            ListTile(
              title: Text('My Profile'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfileScreen(),
                ));
              },
            ),
            ListTile(
              title: Text('Scores List'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UsersListScore(),
                ));
              },
            ),
          ],
        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreatePoll.CreatePollScreen(),
            ),
          );

          // Refresh polls when back from the CreatePollScreen
          setState(() {
            _pollsFuture = fetchPolls();
          });
        },
        child: Icon(Icons.add),
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
  final double yesPercentage;
  final double noPercentage;

  Poll({
    required this.id,
    required this.question,
    required this.voteDeadline,
    required this.pollDeadline,
    required this.correctAnswer,
    this.proofLink,
    required this.yesPercentage,
    required this.noPercentage,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      question: json['question'],
      voteDeadline: json['vote_deadline'],
      pollDeadline: json['poll_deadline'],
      correctAnswer: json['correct_answer'],
      proofLink: json['proof_link'],
      yesPercentage: json['yes_percentage'].toDouble(),
      noPercentage: json['no_percentage'].toDouble(),
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
  bool _isLoggedIn = false;
  final _formKey = GlobalKey<FormState>();
  final authManager = AuthManager();
  VoteChoice? _voteChoice;

  void _checkUserAuthentication() {
    String? token = authManager.authToken;
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _submitVote(VoteChoice choice) async {
    _voteChoice = choice;

    final authToken = authManager.authToken; // Get token from your AuthManager

    final response = await http.post(
      Uri.parse('https://wk.up.railway.app/polls/${widget.poll.id}/vote/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'poll': widget.poll.id, // Assuming poll ID available in widget.poll.id
        'choice': voteChoiceToString(choice),
      }),
    );

    if (response.statusCode == HttpStatus.created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote submitted successfully!')),
      );
    } else {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? authToken = authManager.authToken;
    //int? userId = authManager.getUserIdFromToken();

    return Scaffold(
      appBar: AppBar(
        title: Text('Poll Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap the Column with a SingleChildScrollView
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
              /*if (authToken != null)
                Text('Correct Answer: ${widget.poll.correctAnswer}'),
              SizedBox(height: 20),*/
              if (widget.poll.proofLink != null)
                Text('Proof Link: ${widget.poll.proofLink!}'),
              Container(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        title: "Yes",
                        value: widget.poll.yesPercentage,
                        color: Colors.green,
                      ),
                      PieChartSectionData(
                        title: "No",
                        value: widget.poll.noPercentage,
                        color: Colors.red,
                      ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (authToken != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // To evenly distribute space between buttons
                  children: <Widget>[
                    ElevatedButton(
                      child: Text('Yes'),
                      onPressed: () => _submitVote(VoteChoice.YES),
                    ),
                    ElevatedButton(
                      child: Text('No'),
                      onPressed: () => _submitVote(VoteChoice.NO),
                    ),
                  ],
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
  final int poll;
  final String choice; // changed from voted Yes to choice

  Vote({
    required this.id,
    required this.poll,
    required this.choice,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      poll: json['poll'],
      choice: json['choice'],
    );
  }
}
