import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learningdart/polls_screen.dart';

class ExpiredPollsScreen extends StatefulWidget {
  @override
  _ExpiredPollsScreenState createState() => _ExpiredPollsScreenState();
}

class _ExpiredPollsScreenState extends State<ExpiredPollsScreen> {
  late Future<List<Poll>> _expiredPollsFuture;

  @override
  void initState() {
    super.initState();
    _expiredPollsFuture = fetchExpiredPolls();
  }

  Future<List<Poll>> fetchExpiredPolls() async {
    final response =
        await http.get(Uri.parse('https://wk.up.railway.app/expired_polls/'));

    if (response.statusCode == 200) {
      Iterable jsonResponse = json.decode(response.body);
      return jsonResponse.map((poll) => Poll.fromJson(poll)).toList();
    } else {
      throw Exception('Failed to load expired polls');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expired Polls'),
      ),
      body: FutureBuilder<List<Poll>>(
        future: _expiredPollsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No expired polls found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final expiredPoll = snapshot.data![index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PollDetailsScreen(poll: expiredPoll),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(expiredPoll.question),
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
