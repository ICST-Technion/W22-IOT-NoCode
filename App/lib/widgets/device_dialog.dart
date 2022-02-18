import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/res/custom_icons.dart';

// A general device dialog that is used for all of the dialogs in the project

class DeviceDialog extends StatefulWidget {
  const DeviceDialog({Key key, this.board, this.device, this.title, @required this.pinsStructure, this.buildFunction, this.onInitComplete, this.onPreSave, this.removeButton=false, this.saveButton=true}) : super(key: key);

  final Map<String, dynamic> board;
  final List<Map<String, dynamic>> pinsStructure;
  final dynamic device;
  final String title;
  final Function(Map<String, Map<String, dynamic>>) buildFunction;
  final Function(Map<String, Map<String, dynamic>>) onInitComplete;
  final Function(Map<String, Map<String, dynamic>>) onPreSave;
  final bool removeButton;
  final bool saveButton;

  @override
  _DeviceDialogState createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {

  Map<String, Map<String, dynamic>> _pinsMap;

  List<Map<String, dynamic>> _pinsMapToDbList(Map<String, Map<String, dynamic>> pinsMap) {

    return pinsMap.values.map((e) => {
      "name": e["name"],
      "number": e["number"],
      "value": e["value"]
    }).toList();
  }

  void _pinsStructureToMap(List<Map<String, dynamic>> pinsList) {

    _pinsMap = {};

    for(var i=0; i<pinsList.length; ++i) {
      var pin = pinsList[i];
      _pinsMap[pin["name"]] = {...pin};
    }
  }

  void _fillDbValues(List<dynamic> dbPins) {

    for (var pin in dbPins) {
      _pinsMap[pin["name"]]["number"] = pin["number"];
      _pinsMap[pin["name"]]["value"] = pin["value"];
    }
  }

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
      "devices": widget.board["devices"]
    });

    setState(() {
      _pinsStructureToMap(widget.pinsStructure);
      _fillDbValues(widget.device["pins"]);

      if(widget.onInitComplete != null) {
        widget.onInitComplete(_pinsMap);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> actions = [];

    if(widget.saveButton) {
      actions += [TextButton(
          style: TextButton.styleFrom(
            primary: Colors.white70,
          ),
          child: const Text("Save"),
          onPressed: () {

            List devices = widget.board["devices"];

            if(widget.onPreSave != null) {
              widget.onPreSave(_pinsMap);
            }

            for(var i=0; i<devices.length; ++i) {
              if(devices[i]["name"] == widget.device["name"]) {
                devices[i]["pins"] = _pinsMapToDbList(_pinsMap);
                break;
              }
            }

            FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
              "devices": devices
            });

            const snackBar = SnackBar(content: Text('Device saved'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

            Navigator.pop(context);
          }
      )

      ];
    }

    if(widget.removeButton) {
      actions += [IconButton(
          icon: const Icon(CustomIcons.remove),
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
      )];
    }

    return AlertDialog(
      title: Text(widget.title),
      content: Wrap(
        children: [
            Column(children: [widget.buildFunction(_pinsMap)])
        ]
      ),
      actions: actions,
    );
  }
}