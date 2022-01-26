import 'package:app/screens/board_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/utils/authentication.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';


class BoardsScreen extends StatefulWidget {
  const BoardsScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BoardsScreenState createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {

  final User _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onMenuChanged(int index) async {
    if(index == 2) {
      await Authentication.signOut(context: context);
      const snackBar = SnackBar(content: Text('Signed out'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.pushReplacementNamed(context, "/");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.navy,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CustomColors.navy,
        title: AppBarTitle(title: widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add a board',
        child: const Icon(Icons.add),
        onPressed: () => _registerDevice(context),
      ),
      bottomNavigationBar: BottomNavbar(onChanged: _onMenuChanged),
      body: _queryBoardList()
    );
  }

  /// List devices owned by the authenticated user
  Widget _queryBoardList() {

    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('boards')
          .where('owner', isEqualTo: _user.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            return Column(children: snapshot.data.docs.map((DocumentSnapshot data) {
                return Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.memory, size: 40),
                        title: Text(data.id, style: const TextStyle(fontSize: 24)),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (BuildContext context) {
                            return {'Remove'}.map((String choice) {
                              return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text(choice)
                              );
                            }).toList();
                          },
                          onSelected: (String value) {
                            FirebaseFirestore.instance.collection('board-configs').doc(data.id).delete();
                            data.reference.delete();
                            const snackBar = SnackBar(content: Text('Board deleted'));
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          },
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/board', arguments: BoardArguments(data.reference));
                        }
                      )
                    ],
                  )
                );
              }).toList());
        }
      },
    );
  }

  /// Scan a device, then publish the result
  void _registerDevice(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/scan');
    if (result == null) return;

    // Attach the current user as the device owner
    final Map<String, dynamic> device = result;
    device['owner'] = _user.uid;

    final String deviceId = device['serial_number'];
    var pendingRef = FirebaseFirestore.instance.collection('pending').doc(deviceId);
    pendingRef.set(device);

    const snackBar = SnackBar(content: Text('Registering board'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}