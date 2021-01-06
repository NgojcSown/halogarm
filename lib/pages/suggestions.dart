import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:halogram/models/user.dart';
import 'package:halogram/pages/search.dart';
import 'package:halogram/widgets/header.dart';
import 'package:halogram/widgets/progress.dart';
import 'home.dart';

class Suggestions extends StatefulWidget {
  final User currentUser;
  Suggestions({this.currentUser});
  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {

  List<String> followingList = [];


  buildSuggestions() {
      return buildUsersToFollow();
  }

  buildUsersToFollow() {
    return StreamBuilder(
        stream: usersRef
            .orderBy('timeStamp', descending: false)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuth = widget.currentUser.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            if (isAuth || isFollowingUser)
              return;
            else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
          return Container(
            color: Theme.of(context).primaryColor.withOpacity(.2),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[

                      SizedBox(width: 10.0),
                      Text(
                        "Những người bạn có thể biết",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: userResults,
                ),
              ],
            ),
          );
        });
  }

  getFollowingUsers() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  @override
  void initState() {

    getFollowingUsers();
    super.initState();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isTimeLine: true),
      body: Container(
      child: buildSuggestions(),
      ),
    );
  }
}
