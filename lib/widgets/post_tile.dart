import 'package:flutter/material.dart';
import 'package:halogram/widgets/custom_image.dart';
import 'package:halogram/widgets/post.dart';
import 'package:halogram/pages/post_screen.dart';

class PostTile extends StatelessWidget {
  final Post post;
  showPost(context){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>PostScreen(userId: post.ownerId,postId: post.postId,)));
  }
  PostTile(this.post);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: cachedNetworkImage(post.mediaUrl),
      onTap:()=> showPost(context),
    );
  }
}
