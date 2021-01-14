import 'package:flutter/material.dart';
import 'package:halogram/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  String username;

  submit()
  {
    _formKey.currentState.save();
    Navigator.pop(context,username);
  }
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(context,isTimeLine: false,pageTitle: 'Tạo tài khoản mới'),
      body: Container(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Center(
                child: Text('Nhập Tên hiển thị',
                style: TextStyle(
                  fontSize: 25.0,
                ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  onSaved: (val)=>username=val,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tên hiển thị phải trên 4 ký tự',
                    labelText: 'Tên hiển thị',
                    labelStyle: TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
            ),
            FlatButton(
              onPressed: submit,
              child: Container(
                height: 50.0, // not good for small mobiles please figure out how to solve it
                width: 350.0,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(7.0),
                  //may need to add a color
                ),
                child: Center(
                  child: Text('Hoàn tất',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
