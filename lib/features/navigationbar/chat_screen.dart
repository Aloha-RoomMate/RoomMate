import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("채팅"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).primaryColor.withAlpha(50),
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(Sizes.size5),
        child: Row(children: [Text("채팅채팅채팅채팅채팅채팅채팅채팅채팅채팅채팅채팅채팅채팅")]),
      ),
    );
  }
}
