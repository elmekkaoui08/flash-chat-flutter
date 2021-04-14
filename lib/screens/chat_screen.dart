import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

class ChatScreen extends StatefulWidget {
  static String route = '/chat';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  Firestore _firestore = Firestore.instance;
  String textMessage;
  FirebaseUser user;
  Stream messagesStream;
  var messages = [];
  TextEditingController textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    getCurrentUser();
    //getMessages();
    messagesStream = _firestore.collection('messages').snapshots();
  }

  void getCurrentUser() async {
    try {
      _auth = FirebaseAuth.instance;
      user = await _auth.currentUser();
      if (user != null) {
        print(user.email);
      }
    } catch (e) {
      print('Exception: $e');
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
              onPressed: () {
                //Implement logout functionality
                  _auth.signOut();
                  Navigator.pop(context);
                //getMessages();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            /*Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, index)=> _singleMessageWidget(index),

              ),
            ),*/

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('send_at')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Widget> messagesWidget = [];
                    final messages = snapshot.data.documents.reversed;
                    messages.forEach((element) {
                      final singleMessage = _singleMessageWidget(
                        element.data['messageBody'],
                        element.data['send_at'],
                        element.data['sender'],
                      );
                      messagesWidget.add(singleMessage);
                    });
                    return ListView(
                      reverse: true,
                      children: messagesWidget,
                    );
                  } else {
                    if (!snapshot.hasError) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return Center(
                        child: Container(
                          width: 200,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.red[300],
                              borderRadius: BorderRadius.circular(50)),
                          child: Text(
                            'an error happend please contact the adminstration',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      onChanged: (value) {
                        //Do something with the user input.
                        textMessage = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      _firestore.collection('messages').add({
                        'messageBody': textMessage,
                        'sender': user.email,
                        'user_id': 1,
                        'send_at': DateTime.now()
                      });
                      setState(() {
                        textEditingController.text = '';
                        textMessage = '';
                      });
                    },
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

  Widget _singleMessageWidget( String messageBody, Timestamp sendAt, String sender) {
    final isMe = sender == user.email;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: isMe
                ? BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
              ),
            )
                :
            BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                )),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                isMe ? Container(height: 0, width: 0,): Text(sender, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),),
                Text(messageBody,
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    '${sendAt.toDate().hour.toString()} : ${sendAt.toDate().minute.toString()}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
