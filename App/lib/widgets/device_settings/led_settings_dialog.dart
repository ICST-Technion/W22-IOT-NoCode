import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numberpicker/numberpicker.dart';

class LedSettingsDialog extends StatefulWidget {
  const LedSettingsDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _LedSettingsDialogState createState() => _LedSettingsDialogState();
}

class _LedSettingsDialogState extends State<LedSettingsDialog> {

  Map<String, int> _values;

  final Map<String, Color> _colors = {
    "red": Colors.redAccent,
    "green": Colors.greenAccent,
    "blue": Colors.blueAccent
  };

  dynamic get_pins() {
    return [
      {
        "name": "red",
        "number": _values["red"],
        "value": 0
      },
      {
        "name": "green",
        "number": _values["green"],
        "value": 0
      },
      {
        "name": "blue",
        "number": _values["blue"],
        "value": 0
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    List pins = widget.device["pins"];

    _values = {
      "red": 1,
      "green": 1,
      "blue": 1
    };

    setState(() {
      for (var i = 0; i < pins.length; ++i) {
        String name = pins[i]["name"];
        _values[name] = pins[i]["number"] as int;
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
              _build_pin_row("red"),
              const SizedBox(height: 15),
              _build_pin_row("green"),
              const SizedBox(height: 15),
              _build_pin_row("blue")
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

              const snackBar = SnackBar(content: Text('Led saved'));
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

  Widget _build_pin_row(String color) {
    return Row(
      children: [
        Icon(Icons.emoji_objects_outlined, size: 30,
            color: _colors[color]),
        Text(color[0].toUpperCase()+color.substring(1) + " pin"),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _build_numberpicker(color)
              ],
            )
        )
      ],
    );
  }

  Widget _build_numberpicker(String color) {
    return NumberPicker(
      value: _values[color],
      itemWidth: 55,
      minValue: 1,
      maxValue: 30,
      step: 1,
      axis: Axis.horizontal,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      onChanged: (value) => setState(() => _values[color] = value),
    );
  }

}