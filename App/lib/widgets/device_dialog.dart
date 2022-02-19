import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/res/custom_icons.dart';

// A general device dialog that is used for all of the dialogs in the project

class DeviceDialog extends StatefulWidget {
  const DeviceDialog({Key key, this.board, this.device, this.title, @required this.pinsStructure, this.buildFunction, this.onInitComplete, this.onPreSave, this.removeButton=false, this.saveButton=true}) : super(key: key);

  // Devices' Board's information from DB
  final Map<String, dynamic> board;

  // Pins structure
  final List<Map<String, dynamic>> pinsStructure;

  // Device's information from DB
  final dynamic device;

  // Dialog title
  final String title;

  // A callback function which builds the "inside" of the dialog
  final Function(Map<String, Map<String, dynamic>>) buildFunction;

  // A callback function which is called when the dialog has been initialized
  final Function(Map<String, Map<String, dynamic>>) onInitComplete;

  // A callback function which is called before the data is saved to DB
  final Function(Map<String, Map<String, dynamic>>) onPreSave;

  // Should add a device remove button
  final bool removeButton;

  // Should add a device save button
  final bool saveButton;

  @override
  _DeviceDialogState createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {

  // A map of the current pins configuration of the device
  // The map may contain extra fields that will not be saved in the DB
  Map<String, Map<String, dynamic>> _pinsMap;

  @override
  void initState() {
    super.initState();


    // When the dialog is created make sure that the configuration is reset
    // The current board state will be saved in the board config
    FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
      "devices": widget.board["devices"]
    });

    setState(() {
      // Set pins structure
      _pinsStructureToMap(widget.pinsStructure);

      // Fill pins from DB
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

            // Start the save process

            List devices = widget.board["devices"];

            if(widget.onPreSave != null) {
              widget.onPreSave(_pinsMap);
            }

            // Find the device from the initial DB state given
            // and set its pins with the updated values from the pins map
            for(var i=0; i<devices.length; ++i) {
              if(devices[i]["name"] == widget.device["name"]) {
                devices[i]["pins"] = _pinsMapToDbList(_pinsMap);
                break;
              }
            }

            // Save the board's devices
            FirebaseFirestore.instance.collection("board-configs").doc(widget.board["id"]).update({
              "devices": devices
            });

            const snackBar = SnackBar(content: Text('Device saved'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);

            // When save is complete, close the dialog
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

            // Remove the device from the boards collection
            FirebaseFirestore.instance.collection("boards").doc(widget.board["id"]).update({
              "devices": FieldValue.arrayRemove([widget.device])
            });

            // Remove the device from the board configs collection
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

  // Converts the pins map into a list that is ready to be sent to DB
  List<Map<String, dynamic>> _pinsMapToDbList(Map<String, Map<String, dynamic>> pinsMap) {

    return pinsMap.values.map((e) => {
      "name": e["name"],
      "number": e["number"],
      "value": e["value"]
    }).toList();
  }

  // Converts the initial pins structure list into the pins map
  void _pinsStructureToMap(List<Map<String, dynamic>> pinsList) {

    _pinsMap = {};

    for(var i=0; i<pinsList.length; ++i) {
      var pin = pinsList[i];
      _pinsMap[pin["name"]] = {...pin};
    }
  }

  // Fills the initial values from the DB into the pins map
  void _fillDbValues(List<dynamic> dbPins) {

    for (var pin in dbPins) {
      _pinsMap[pin["name"]]["number"] = pin["number"];
      _pinsMap[pin["name"]]["value"] = pin["value"];
    }
  }
}