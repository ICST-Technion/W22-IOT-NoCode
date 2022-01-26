import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';

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

  @override
  void initState() {
    super.initState();
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
        bottomNavigationBar: BottomNavbar(),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        tooltip: 'Add a device',
        children: [
          SpeedDialChild(
            child: const Icon(Icons.emoji_objects),
            backgroundColor: CustomColors.ledColor,
            foregroundColor: Colors.white,
            label: 'LED RGB',
            onTap: () {add_device_dialog("led", boardDocument.id);}
          ),
          SpeedDialChild(
              child: const Icon(Icons.sensors),
              backgroundColor: CustomColors.sensorColor,
              foregroundColor: Colors.white,
              label: 'Sensor',
              onTap: () {add_device_dialog("sensor", boardDocument.id);}
          ),
          SpeedDialChild(
              child: const Icon(Icons.iso),
              backgroundColor: CustomColors.servoColor,
              foregroundColor: Colors.white,
              label: 'Servo engine',
              onTap: () {add_device_dialog("servo", boardDocument.id);}
          )
        ],
      ),
        body: _queryDeviceList(boardDocument)
    );
  }

  Widget _queryDeviceList(DocumentReference board_ref) {

    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('boards').doc(board_ref.id).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            Map<String, dynamic> data = snapshot.data.data() as Map<String, dynamic>;
            return GridView.count(
                primary: false,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                padding: const EdgeInsets.all(30),
                children: (data["devices"] as List<dynamic>).map((device){

                IconData icon;
                Color color;

                if(device["type"] == "led") {
                  icon = Icons.emoji_objects_outlined;
                  color = CustomColors.ledColor;
                }
                else if(device["type"] == "sensor") {
                  icon = Icons.sensors;
                  color = CustomColors.sensorColor;
                }
                else if(device["type"] == "servo") {
                  icon = Icons.iso;
                  color = CustomColors.servoColor;
                }
                else {
                  print("Not a legal device type");
                }
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(icon),
                        iconSize: 40,
                        onPressed: () {

                        },
                      ),
                      Text(device["name"])
                    ]
                  )
                );
                }).toList());
        }
      },
    );
  }

  void add_device_dialog(String device_type, String board_id) => showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Device name"),
        content: TextField(
          onSubmitted: (String value) {
            FirebaseFirestore.instance.collection("board-configs").doc(board_id).update({
              "devices": FieldValue.arrayUnion([{
                "name": value,
                "type": device_type,
                "pins": []
              }])
            });

            const snackBar = SnackBar(content: Text('Device added'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

            Navigator.pop(context);
          },
          decoration: const InputDecoration(hintText: "Enter device's name"),
        ),
      );
    });

}