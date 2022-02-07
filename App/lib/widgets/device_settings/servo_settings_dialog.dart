import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numberpicker/numberpicker.dart';

class ServoSettingsDialog extends StatefulWidget {
  const ServoSettingsDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _ServoSettingsDialogState createState() => _ServoSettingsDialogState();
}

class _ServoSettingsDialogState extends State<ServoSettingsDialog> {

  int _pin_number;

  dynamic get_pins() {
    return [
      {
        "name": "control",
        "number": _pin_number,
        "value": 0
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    List pins = widget.device["pins"];

    _pin_number = 0;

    setState(() {
      if(pins.isNotEmpty) {
        _pin_number = pins[0]["number"] as int;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Wrap(
        children: [
          Column(
            children: [
              _build_pin_row()
          ])
        ]
      ),
      actions: [
        TextButton(
            style: TextButton.styleFrom(
              primary: Colors.white70,
            ),
            child: const Text("Save"),
            onPressed: () {

              List devices = widget.board["devices"];

              for(var i=0; i<devices.length; ++i) {
                if(devices[i]["name"] == widget.device["name"]) {
                  devices[i]["pins"] = get_pins();
                  break;
                }
              }

              FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
                "devices": devices
              });

              const snackBar = SnackBar(content: Text('Servo saved'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              Navigator.pop(context);
            }
        ),
        IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Remove device",
            onPressed: () {
              FirebaseFirestore.instance.collection("boards").doc(widget.board["id"]).update({
                "devices": FieldValue.arrayRemove([widget.device])
              });
              FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
                "devices": FieldValue.arrayRemove([widget.device])
              });

              const snackBar = SnackBar(content: Text('Device removed'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              Navigator.pop(context);
            }
        )
      ],
    );
  }

  Widget _build_pin_row() {
    return Row(
      children: [
        Icon(Icons.iso, size: 30,
            color: Colors.white70),
        Text("Control pin"),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _build_numberpicker()
              ],
            )
        )
      ],
    );
  }

  Widget _build_numberpicker() {
    return NumberPicker(
      value: _pin_number,
      itemWidth: 55,
      minValue: 1,
      maxValue: 30,
      step: 1,
      axis: Axis.horizontal,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      onChanged: (value) => setState(() => _pin_number = value),
    );
  }

}