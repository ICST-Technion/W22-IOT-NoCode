import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/widgets/app_bar_title.dart';

class BoardArguments {
  final DocumentReference<Object> board_ref;

  BoardArguments(this.board_ref);
}


class BoardScreen extends StatefulWidget {
  const BoardScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {

  final User _user = FirebaseAuth.instance.currentUser;
  var _state = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _state = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final boardDocument = (ModalRoute.of(context).settings.arguments as BoardArguments).board_ref;

    return Scaffold(
      backgroundColor: CustomColors.navy,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CustomColors.navy,
        title: AppBarTitle(title: boardDocument.id),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
        IconButton(
          iconSize: 60,
          icon: _state ? const Icon(Icons.emoji_objects) : const Icon(Icons.emoji_objects_outlined),
          tooltip: 'Light bulb',
          onPressed: () {

            setState(() {
              _state = !_state;
            });

            var doc = FirebaseFirestore.instance.collection('board-configs').doc(boardDocument.id);
            doc.update({
              "config": {
                "pins": [
                  {
                    "number": 22,
                    "value": _state ? 1 : 0
                  }
                ]
            }
            });

          },
        ),
          Text("Light bulb")
      ]
      )
    );
  }
}