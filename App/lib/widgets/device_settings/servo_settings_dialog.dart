import 'package:app/res/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/device_settings/settings_dialog.dart';


class ServoSettingsDialog extends StatefulWidget {
  const ServoSettingsDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  // Devices' Board's information from DB
  final Map<String, dynamic> board;

  // Device's information from DB
  final dynamic device;

  // Dialog title
  final String title;

  @override
  _ServoSettingsDialogState createState() => _ServoSettingsDialogState();
}

class _ServoSettingsDialogState extends State<ServoSettingsDialog> {

  @override
  Widget build(BuildContext context) {
    return SettingsDialog(
      board: widget.board,
      device: widget.device,
      title: widget.title,
      pinsStructure: const [
        {
          "name": "control",
          "number": 1,
          "value": 0,
          "icon": CustomIcons.servo,
          "color": Colors.white70
        }
      ]
    );
  }
}