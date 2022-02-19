import 'package:flutter/material.dart';
import 'package:knob_widget/knob_widget.dart';
import 'package:app/widgets/device_dialog.dart';

class ServoControlDialog extends StatefulWidget {
  const ServoControlDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  // Devices' Board's information from DB
  final Map<String, dynamic> board;

  // Device's information from DB
  final dynamic device;

  // Dialog title
  final String title;

  @override
  _ServoControlDialogState createState() => _ServoControlDialogState();
}

class _ServoControlDialogState extends State<ServoControlDialog> {

  KnobController _controller;
  double _knobValue = 0;

  void _valueChangedListener(double value) {
    setState(() {
      _knobValue = value;
    });
  }

  @override
  void dispose() {
    _controller.removeOnValueChangedListener(_valueChangedListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeviceDialog(
      board: widget.board,
      device: widget.device,
      title: widget.title,
      removeButton: false,
      pinsStructure: const [
        {
          "name": "control",
          "number": 1,
          "value": 0
        }
      ],
      onInitComplete: (Map<String, Map<String, dynamic>> pinsMap) {

        _knobValue = pinsMap["control"]["value"].toDouble();

        _controller = KnobController(
          initial: _knobValue,
          minimum: 0,
          maximum: 180,
          startAngle: 0,
          endAngle: 180,
        );

        _controller.addOnValueChangedListener(_valueChangedListener);
      },
      onPreSave: (Map<String, Map<String, dynamic>> pinsMap) {
        pinsMap["control"]["value"] = _knobValue.toInt();
      },
      buildFunction: (Map<String, Map<String, dynamic>> pinsMap) {
        return Column(children: [
            Text("Value: " + _knobValue.round().toString()),
            const SizedBox(height: 20),
            Center(child: _buildKnob())
        ]);
      }
    );
  }

  Widget _buildKnob() {
    return Knob(
        controller: _controller,
        width: 100,
        height: 100,
        style: KnobStyle(
        labelStyle: Theme.of(context).textTheme.bodyText1,
          tickOffset: 1,
          labelOffset: 10,
          minorTicksPerInterval: 50,
        ),
    );
  }
}