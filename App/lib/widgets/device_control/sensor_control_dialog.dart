import 'package:flutter/material.dart';
import 'package:knob_widget/knob_widget.dart';
import 'package:app/widgets/device_dialog.dart';

class SensorControlDialog extends StatefulWidget {
  const SensorControlDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _SensorControlDialogState createState() => _SensorControlDialogState();
}

class _SensorControlDialogState extends State<SensorControlDialog> {

  @override
  Widget build(BuildContext context) {
    return DeviceDialog(
      board: widget.board,
      device: widget.device,
      title: widget.title,
      removeButton: false,
      pinsStructure: const [
        {
          "name": "data",
          "number": 1,
          "value": 0
        }
      ],
      buildFunction: (Map<String, Map<String, dynamic>> pinsMap) {
        return Column(children: [
            const SizedBox(height: 20)
        ]);
      }
    );
  }
}