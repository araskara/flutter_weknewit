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
import 'package:learningdart/ExpiredPollsScreen.dart';

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
  List<String> _categories = [
    'All',
    'Politics',
    'Economy',
    'Sport',
    'Science',
    'Art',
    'others'
  ]; // add more as needed

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

  Future<void> _submitVote(VoteChoice choice, int pollId) async {
    _voteChoice = choice;
    final authToken = authManager.authToken;

    final response = await http.post(
      Uri.parse('https://wk.up.railway.app/polls/$pollId/vote/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'poll': pollId,
        'choice': voteChoiceToString(choice),
      }),
    );

    // Handle response
    if (response.statusCode == HttpStatus.created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote submitted successfully!')),
      );
    } else {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      var responseBody = jsonDecode(response.body);
      var errorMessage = responseBody['error'] ?? 'Error submitting vote.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

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
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Polls List'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _categories
                .map((String category) => Tab(text: category))
                .toList(),
          ),
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
                title: Text('Expired Polls'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ExpiredPollsScreen(),
                  ));
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: _categories.map((String category) {
            return FutureBuilder<List<Poll>>(
              future: _pollsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No polls found'));
                } else {
                  List<Poll> displayedPolls;
                  if (category == 'All') {
                    displayedPolls = snapshot.data!;
                  } else {
                    displayedPolls = snapshot.data!
                        .where((poll) => poll.category == category)
                        .toList();
                  }

                  return ListView.builder(
                    itemCount: displayedPolls.length,
                    itemBuilder: (context, index) {
                      final poll = displayedPolls[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PollDetailsScreen(poll: poll),
                                    ),
                                  );
                                },
                                child: Text(
                                  poll.question,
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                String? authToken = AuthManager().authToken;
                                if (authToken != null) {
                                  return Row(
                                    children: [
                                      ElevatedButton(
                                        child: Text('Yes'),
                                        onPressed: () => _submitVote(
                                            VoteChoice.YES, poll.id),
                                      ),
                                      SizedBox(width: 8.0),
                                      ElevatedButton(
                                        child: Text('No'),
                                        onPressed: () =>
                                            _submitVote(VoteChoice.NO, poll.id),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreatePoll.CreatePollScreen(),
              ),
            );
            setState(() {
              _pollsFuture = fetchPolls();
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class Poll {
  final int id;
  final String question;
  final String voteDeadline;
  final String pollDeadline;
  final String? correctAnswer;
  final String? proofLink;
  final double yesPercentage;
  final double noPercentage;
  final String category;

  Poll({
    required this.id,
    required this.question,
    required this.voteDeadline,
    required this.pollDeadline,
    required this.correctAnswer,
    this.proofLink,
    required this.yesPercentage,
    required this.noPercentage,
    required this.category,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      question: json['question'],
      voteDeadline: json['vote_deadline'],
      pollDeadline: json['poll_deadline'],
      correctAnswer: json['correct_answer'], // It can be null
      proofLink: json['proof_link'],
      yesPercentage: json['yes_percentage'].toDouble(),
      noPercentage: json['no_percentage'].toDouble(),
      category: json['category'],
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
