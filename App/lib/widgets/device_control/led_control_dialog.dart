import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:app/widgets/device_dialog.dart';


class LedControlDialog extends StatefulWidget {
  const LedControlDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _LedControlDialogState createState() => _LedControlDialogState();
}

class _LedControlDialogState extends State<LedControlDialog> {

  final Map<String, int> _pins = {};

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

  @override
  Widget build(BuildContext context) {

    return DeviceDialog(
        board: widget.board,
        device: widget.device,
        title: widget.title,
        removeButton: false,
        pinsStructure: const [
          {
            "name": "red",
            "number": 1,
            "value": 0
          },
          {
            "name": "green",
            "number": 2,
            "value": 0
          },
          {
            "name": "blue",
            "number": 3,
            "value": 0
          }
        ],
        onInitComplete: (Map<String, Map<String, dynamic>> pinsMap) {

          _pins["red"] = pinsMap["red"]["value"];
          _pins["green"] = pinsMap["green"]["value"];
          _pins["blue"] = pinsMap["blue"]["value"];
        },
        onPreSave: (Map<String, Map<String, dynamic>> pinsMap) {
          pinsMap["red"]["value"] = _pins["red"];
          pinsMap["green"]["value"] = _pins["green"];
          pinsMap["blue"]["value"] = _pins["blue"];
        },
        buildFunction: (Map<String, Map<String, dynamic>> pinsMap) {
          return Column(children: [
            _build_pin_row("red"),
            const SizedBox(height: 15),
            _build_pin_row("green"),
            const SizedBox(height: 15),
            _build_pin_row("blue")
          ]);
        }
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
      value: _pins[color] == 1 ? true : false,
      borderRadius: 30.0,
      padding: 8.0,
      showOnOff: true,
      onToggle: (val) {
        setState(() {
          _pins[color] = val ? 1 : 0;
        });
      },
    );
  }
}