import 'package:app/res/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/device_settings/settings_dialog.dart';


class SensorSettingsDialog extends StatefulWidget {
  const SensorSettingsDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  // Devices' Board's information from DB
  final Map<String, dynamic> board;

  // Device's information from DB
  final dynamic device;

  // Dialog title
  final String title;

  @override
  _SensorSettingsDialogState createState() => _SensorSettingsDialogState();
}

class _SensorSettingsDialogState extends State<SensorSettingsDialog> {

  @override
  Widget build(BuildContext context) {
    return SettingsDialog(
      board: widget.board,
      device: widget.device,
      title: widget.title,
      pinsStructure: const [
        {
          "name": "data",
          "number": 1,
          "value": 0, // dummy
          "icon": CustomIcons.sensor,
        },
      ]
    );
  }
}