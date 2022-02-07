import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numberpicker/numberpicker.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key key, this.board, this.device, this.title, this.getPins}) : super(key: key);

  final Map<String, dynamic> board;
  final dynamic device;
  final String title;
  final List<Map<String, dynamic>> Function() getPins;

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {

  Map<String, Map<String, dynamic>> _pinsMap;

  Map<String, Map<String, dynamic>> _pinsListToMap(List<Map<String, dynamic>> pinsList) {

    Map<String, Map<String, dynamic>> pinsMap;

    for(var i=0; i<pinsList.length; ++i) {
      var pin = pinsList[i];
      pinsMap[pin["name"]] = pin;
    }

    return pinsMap;
  }

  List<Map<String, dynamic>> _pinsMapToDbList(Map<String, Map<String, dynamic>> pinsMap) {

    return pinsMap.values.map((e) => {
      "name": e["name"],
      "number": e["number"],
      "value": 0,
    })
  }

  Map<String, Map<String, dynamic>> _fillDbValues(Map<String, Map<String, dynamic>> pinsMap, List<Map<String, dynamic>> dbPins) {

    for (var i = 0; i < dbPins.length; ++i) {
      var pin = dbPins[i];
      pinsMap[pin["name"]]["number"] = pin["number"] as int;
    }

    return pinsMap;
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _pinsMap = _pinsListToMap(widget.getPins());
      _pinsMap = _fillDbValues(_pinsMap, widget.device["pins"]);
    });
  }

  List<Widget> _buildPinRows(Map<String, Map<String, dynamic>> pinsMap) {

    List<Map<String, dynamic>> pinsList = _pinsMap.values;
    List<Widget> widgets = [];

    for(var i=0; i<pinsList.length; ++i) {
      var pin = pinsList[i];

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
                      maxValue: 30,
                      step: 1,
                      axis: Axis.horizontal,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black26),
                      ),
                      onChanged: (value) => setState(() => _pinsMap[pin["name"]]["number"] = value),
                    )
                  ],
                )
            )
        ]),
        const SizedBox(height: 15),
      ]
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Wrap(
        children: [
          Column(children: _buildPinRows(_pinsMap))
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
                  devices[i]["pins"] = _pinsMapToDbList(_pinsMap);
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
}