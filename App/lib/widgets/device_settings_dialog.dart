import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DeviceSettingsDialog extends StatefulWidget {
  const DeviceSettingsDialog({Key key, this.board_ref, this.device}) : super(key: key);

  final DocumentReference board_ref;
  final dynamic device;

  @override
  _DeviceSettingsDialogState createState() => _DeviceSettingsDialogState();
}

class _DeviceSettingsDialogState extends State<DeviceSettingsDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Device settings"),
      content: Wrap(
        children: [
          Text("lol")
        ],
      ),
      actions: [
        TextButton(
            child: Text("Remove device"),
            onPressed: () {
              widget.board_ref.update({
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