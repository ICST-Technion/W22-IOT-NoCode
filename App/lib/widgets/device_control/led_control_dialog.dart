import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_switch/flutter_switch.dart';


class LedControlDialog extends StatefulWidget {
  const LedControlDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _LedControlDialogState createState() => _LedControlDialogState();
}

class _LedControlDialogState extends State<LedControlDialog> {

  Map<String, Map> _pins = {};

  final Map<String, Color> _active_colors = {
    "red": Colors.redAccent,
    "green": Colors.green,
    "blue": Colors.blueAccent
  };

  final Map<String, Color> _inactive_colors = {
    "red": const Color(0xBDCE7676),
    "green": const Color(0x4D6CC770),
    "blue": const Color(0x4D81A7C9)
  };

  dynamic get_pins() {
    return [
      {
        "name": "red",
        "number": _pins["red"]["number"],
        "value": _pins["red"]["value"]
      },
      {
        "name": "green",
        "number": _pins["green"]["number"],
        "value": _pins["green"]["value"]
      },
      {
        "name": "blue",
        "number": _pins["blue"]["number"],
        "value": _pins["blue"]["value"]
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      for(int i=0; i<widget.device["pins"].length; ++i) {
        var pin = widget.device["pins"][i];
        _pins[pin["name"]] = {
          "number": pin["number"],
          "value": pin["value"]
        };
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
      )
    );
  }

  Widget _build_pin_row(String color) {
    return Row(
      children: [
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _build_switch(color)
              ],
            )
        )
      ],
    );
  }

  Widget _build_switch(String color) {
    return FlutterSwitch(
      activeColor: _active_colors[color],
      inactiveColor: _inactive_colors[color],
      width: 125.0,
      height: 55.0,
      valueFontSize: 25.0,
      toggleSize: 45.0,
      value: _pins[color]["value"] == 1 ? true : false,
      borderRadius: 30.0,
      padding: 8.0,
      showOnOff: true,
      onToggle: (val) {
        setState(() {
          _pins[color]["value"] = val ? 1 : 0;

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

        });
      },
    );
  }

}