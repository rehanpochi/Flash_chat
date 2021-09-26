import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/mySql.dart';
import 'package:mysql1/mysql1.dart' as mysql;

final _firebase = Firestore.instance;
final _auth = FirebaseAuth.instance;
FirebaseUser loggedInUser;
final messageController = TextEditingController();

var db = MySql();
var deptName = '';

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageTextWritten;

  bool isEnabled = false;

  bool isButtonEnabled() {
    if (messageTextWritten == null) {
      return false;
    }
    return true;
  }

  void getDeptName() async {
    //MySqlConnection conn = await db.getConnection();

    // print(conn.query('select from test.department where dept_id = 1;'));

    db.getConnection().then((conn) {
      String sql = 'select from test.department where dept_id = 1;';
      conn.query(sql).then((results) {
        for (var row in results) {
          print(row[0]);
          setState(() {
            deptName = row[0];
          });
        }
      });
    });
  }

  void getCurrentUser() async {
    try {
      var user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getDeptName();
  }

  void snapShotStreams() async {
    await for (var snapshot
        in _firebase.collection('textmessages').snapshots()) {
      for (var message in snapshot.documents) {
        print(message.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStreams(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        messageTextWritten = value;
                        if (messageTextWritten != "") {
                          setState(() {
                            isEnabled = true;
                          });
                        } else {
                          setState(() {
                            isEnabled = false;
                          });
                        }
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  RaisedButton(
                    onPressed: isEnabled
                        ? () {
                            getDeptName();
                            messageController.clear();
                            _firebase.collection('textmessages').add({
                              'text': messageTextWritten,
                              'user_email': loggedInUser.email,
                            });
                            print(' message is $messageTextWritten ');
                            if (messageTextWritten == '') {
                              setState(() {
                                isEnabled = false;
                              });
                            }
                          }
                        : null,
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BubbleMessage extends StatelessWidget {
  BubbleMessage({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          Material(
            elevation: 5,
            borderRadius: isMe
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    topLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                //textAlign: isMe ? TextAlign.right : TextAlign.right,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          Text(
            deptName,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStreams extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebase.collection('textmessages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<BubbleMessage> bubbleWidgets = [];
        for (var message in messages) {
          final messageText = message.data['text'];
          final messageSender = message.data['user_email'];
          final currentUser = loggedInUser.email;
          final messageBubble = BubbleMessage(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender);

          bubbleWidgets.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: bubbleWidgets,
          ),
        );
      },
    );
  }
}
