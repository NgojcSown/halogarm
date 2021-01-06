import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:halogram/models/user.dart';
import 'package:halogram/pages/activity_feed.dart';
import 'package:halogram/pages/comments.dart';
import 'package:halogram/pages/home.dart';
import 'package:halogram/widgets/custom_image.dart';
import 'package:halogram/widgets/progress.dart';

class Post extends StatefulWidget {
  final String ownerId, postId, username, location, caption, mediaUrl;
  final dynamic likes;
  Post({
    this.username,
    this.location,
    this.mediaUrl,
    this.postId,
    this.caption,
    this.likes,
    this.ownerId,
  });
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      username: doc['username'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      caption: doc['caption'],
      likes: doc['likes'],
    );
  }
  int getLikesCount(likes) {
    if (likes == null) return 0;
    int likesCount = 0;
    likes.values.forEach((val) {
      if (val == true) likesCount++;
    });
    return likesCount;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        username: this.username,
        ownerId: this.ownerId,
        mediaUrl: this.mediaUrl,
        location: this.location,
        caption: this.caption,
        likes: this.likes,
        likesCount: getLikesCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String ownerId, postId, username, location, caption, mediaUrl;
  final String currentUserId = currentUser?.id;
  Map likes;
  int likesCount;
  bool isLiked;
  bool showHeart = false;
  _PostState(
      {this.username,
      this.location,
      this.mediaUrl,
      this.postId,
      this.caption,
      this.likes,
      this.ownerId,
      this.likesCount});
  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.teal,
          ),
          title: Text(
            user.username,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => showProfile(context, profileId: ownerId),
          subtitle: Text(location),
          trailing: ownerId==currentUserId?IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ):Text(""),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Xóa bài viết này?"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  "Xóa",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context)=>Home()
                  ));
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text(
                  "Hủy bỏ",
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  deletePost() async {
    // delete post itself
    postsRef
        .document(ownerId)
        .collection("usersPosts")
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete img from database
    storageRef.child("post_$postId.jpg").delete();
    // delete activity feed
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .where("postId", isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc){
        if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .document(postId)
        .collection("comment")
        .getDocuments();
    commentsSnapshot.documents.forEach((doc){
        if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  addLikeToActivityFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timeStamp,
      });
    }
  }

  removeLikeFromFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) doc.reference.delete();
      });
    }
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef
          .document(ownerId)
          .collection('usersPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      removeLikeFromFeed();
      setState(() {
        likesCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('usersPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likesCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: .8, end: 1.6),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 100.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  showComments(BuildContext context,
      {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        mediaUrl: mediaUrl,
      );
    }));
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 0, left: 20, bottom: 20),
            ),
            GestureDetector(

              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20,top: 10),
              child: Text(
                '$likesCount likes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$username ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(caption),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
