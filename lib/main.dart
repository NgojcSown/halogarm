import 'package:flutter/material.dart';
import 'package:halogram/pages/home.dart';

void main() {
 // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_){});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xff000a12),
        accentColor: Color(0xff00675b),
      ),
      title: 'Halogram',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
