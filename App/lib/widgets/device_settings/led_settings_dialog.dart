import 'package:app/res/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/device_settings/settings_dialog.dart';


class LedSettingsDialog extends StatefulWidget {
  const LedSettingsDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _LedSettingsDialogState createState() => _LedSettingsDialogState();
}

class _LedSettingsDialogState extends State<LedSettingsDialog> {

  @override
  Widget build(BuildContext context) {
    return SettingsDialog(
      board: widget.board,
      device: widget.device,
      title: widget.title,
      pinsStructure: const [
        {
          "name": "red",
          "number": 1,
          "value": 0,
          "icon": CustomIcons.led,
          "color": Colors.redAccent
        },
        {
          "name": "green",
          "number": 2,
          "value": 0,
          "icon": CustomIcons.led,
          "color": Colors.greenAccent
        },
        {
          "name": "blue",
          "number": 3,
          "value": 0,
          "icon": CustomIcons.led,
          "color": Colors.blueAccent
        }
      ],
    );
  }
}