import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'package:app/widgets/device_control/led_control_dialog.dart';
import 'package:app/widgets/device_settings/led_settings_dialog.dart';
import 'package:app/widgets/device_control/servo_control_dialog.dart';
import 'package:app/widgets/device_settings/servo_settings_dialog.dart';
import 'package:app/screens/sensor_control_screen.dart';
import 'package:app/widgets/device_settings/sensor_settings_dialog.dart';
import 'package:app/res/custom_icons.dart';


class BoardArguments {
  final DocumentReference<Object> boardRef;

  BoardArguments(this.boardRef);
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

    final boardDocument = (ModalRoute.of(context).settings.arguments as BoardArguments).boardRef;

    return Scaffold(
      backgroundColor: CustomColors.navy,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CustomColors.navy,
        title: AppBarTitle(title: boardDocument.id),
      ),
        bottomNavigationBar: const BottomNavbar(),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        tooltip: 'Add a device',
        buttonSize: const Size(60, 60),
        childrenButtonSize: const Size(80, 80),
        spaceBetweenChildren: 10,
        children: [
          SpeedDialChild(
            child: const Icon(CustomIcons.led, size: 40),
            backgroundColor: CustomColors.ledColor,
            foregroundColor: Colors.white,
            label: 'LED RGB',
            onTap: () {_showAddDeviceDialog("led", boardDocument.id);}
          ),
          SpeedDialChild(
              child: const Icon(CustomIcons.sensor, size: 40),
              backgroundColor: CustomColors.sensorColor,
              foregroundColor: Colors.white,
              label: 'Sensor',
              onTap: () {_showAddDeviceDialog("sensor", boardDocument.id);}
          ),
          SpeedDialChild(
              child: const Icon(CustomIcons.servo, size: 40),
              backgroundColor: CustomColors.servoColor,
              foregroundColor: Colors.white,
              label: 'Servo motor',
              onTap: () {_showAddDeviceDialog("servo", boardDocument.id);}
          )
        ],
      ),
        body: _queryDeviceList(boardDocument)
    );
  }

  Widget _queryDeviceList(DocumentReference boardRef) {

    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('boards').doc(boardRef.id).snapshots(),
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
                StatefulWidget settingsDialog;
                StatefulWidget controlDialog;

                if(device["type"] == "led") {
                  icon = CustomIcons.led;
                  color = CustomColors.ledColor;
                  settingsDialog = LedSettingsDialog(
                    board: data,
                    device: device,
                    title: 'Led RGB settings',
                    );
                  controlDialog = LedControlDialog(
                    board: data,
                    device: device,
                    title: device["name"]+" LED",
                  );
                }
                else if(device["type"] == "sensor") {
                  icon = CustomIcons.sensor;
                  color = CustomColors.sensorColor;
                  settingsDialog = SensorSettingsDialog(
                    board: data,
                    device: device,
                    title: 'Sensor settings',
                  );
                  controlDialog = SensorControlScreen(
                      board: data,
                      device: device,
                      title: device["name"]+" sensor"
                  );
                }
                else if(device["type"] == "servo") {
                  icon = CustomIcons.servo;
                  color = CustomColors.servoColor;
                  settingsDialog = ServoSettingsDialog(
                    board: data,
                    device: device,
                    title: 'Servo settings',
                  );
                  controlDialog = ServoControlDialog(
                    board: data,
                    device: device,
                    title: device["name"]+" servo"
                  );
                }
                else {
                  if (kDebugMode) {
                    print("Not a legal device type");
                  }
                }
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(15),
                    ),
                    border: Border.all(
                      width: 0.5,
                      color: darken(color, 0.4)
                    ),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(2, 3)
                    )]
                  ),
                  child: InkWell(
                    child: Ink(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(icon, size: 50),
                          Text(device["name"])
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                    ),
                    onTap: () {
                      // For the sensor we navigate to a new route
                      if(device["type"] == "sensor") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => controlDialog));
                      }
                      else { // For other devices we open a dialog
                        showDialog(context: context, builder: (BuildContext context) {
                          return controlDialog;
                        });
                      }
                    },
                    onLongPress: () {
                      // Settings dialog
                      showDialog(context: context, builder: (BuildContext context) {
                        return settingsDialog;
                      });
                    },
                  ),
                );
            }).toList());
        }
      },
    );
  }

  void _showAddDeviceDialog(String deviceType, String boardId) => showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Device name"),
        content: TextField(
          onSubmitted: (String value) {
            FirebaseFirestore.instance.collection("board-configs").doc(boardId).update({
              "devices": FieldValue.arrayUnion([{
                "name": value,
                "type": deviceType,
                "active": 0,
                "pins": []
              }])
            });

            const snackBar = SnackBar(content: Text('Adding device'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

            Navigator.pop(context);
          },
          decoration: const InputDecoration(hintText: "Enter device's name"),
        ),
      );
  });
}