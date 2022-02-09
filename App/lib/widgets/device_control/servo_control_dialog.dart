import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knob_widget/knob_widget.dart';


class ServoControlDialog extends StatefulWidget {
  const ServoControlDialog({Key key, this.board, this.device, this.title}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;

  @override
  _ServoControlDialogState createState() => _ServoControlDialogState();
}

class _ServoControlDialogState extends State<ServoControlDialog> {

  int _control_number;
  int _control_value;

  KnobController _controller;
  double _knobValue;

  dynamic get_pins() {
    return [
      {
        "name": "control",
        "number": _control_number,
        "value": _knobValue.round().toInt()
      }
    ];
  }

  @override
  void initState() {
    super.initState();

    setState(() {

      for(int i=0; i<widget.device["pins"].length; ++i) {
        var pin = widget.device["pins"][i];
        _control_number = pin["number"];
        _control_value = pin["value"];
        break;
      }

      _knobValue = _control_value.toDouble();
      _controller = KnobController(
        initial: _knobValue,
        minimum: 0,
        maximum: 180,
        startAngle: 0,
        endAngle: 180,
      );

      _controller.addOnValueChangedListener(valueChangedListener);
    });
  }

  void valueChangedListener(double value) {

    setState(() {
      _knobValue = value;
    });
  }

  @override
  void dispose() {
    _controller.removeOnValueChangedListener(valueChangedListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Wrap(
        children: [
          Text("Current angle: " + _knobValue.round().toString()),
          Column(
            children: [
              SizedBox(height: 30),
              Center(child: build_knob()),
            ])
        ]
      ),
      actions: [
        TextButton(onPressed: () {
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

          Navigator.pop(context);

        }, child: const Text("Save"))
      ],
    );
  }

  Widget build_knob() {
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