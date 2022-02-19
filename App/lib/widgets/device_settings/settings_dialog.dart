import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:app/widgets/device_dialog.dart';

// A generic device settings dialog

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key key, this.board, this.device, this.title, this.pinsStructure}) : super(key: key);

  // Devices' Board's information from DB
  final Map<String, dynamic> board;

  // Device's information from DB
  final dynamic device;

  // Dialog title
  final String title;

  // Pins structure
  final List<Map<String, dynamic>> pinsStructure;

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {

  List<Widget> _buildPinRows(Map<String, Map<String, dynamic>> pinsMap) {

    List<Widget> widgets = [];

    pinsMap.forEach((key, pin) {
      widgets += [
        Row(
            children: [
              Icon(pin["icon"], size: 30, color: pin["color"]),
              Text(pin["name"]+" pin"),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      NumberPicker(
                        value: pin["number"],
                        itemWidth: 55,
                        minValue: 1,
                        maxValue: 39,
                        step: 1,
                        axis: Axis.horizontal,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black26),
                        ),
                        onChanged: (value) => setState(() => pinsMap[pin["name"]]["number"] = value),
                      )
                    ],
                  )
              )
            ]),
        const SizedBox(height: 15)
      ];
    });

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return DeviceDialog(
        board: widget.board,
        device: widget.device,
        title: widget.title,
        removeButton: true,
        pinsStructure: widget.pinsStructure,
        buildFunction: (Map<String, Map<String, dynamic>> pinsMap) {
          return Column(children: _buildPinRows(pinsMap));
        }
    );
  }
}