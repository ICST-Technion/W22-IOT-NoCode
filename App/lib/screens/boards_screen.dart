import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/screens/sign_in_screen.dart';
import 'package:app/utils/authentication.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'package:app/screens/scan_screen.dart';


class BoardsScreen extends StatefulWidget {

  @override
  _BoardsScreenState createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {

  User _user = FirebaseAuth.instance.currentUser;

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _onMenuChanged(int index) async {
    if(index == 1) {
      await Authentication.signOut(context: context);
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
        title: AppBarTitle(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _registerDevice(context),
      ),
      bottomNavigationBar: BottomNavbar(onChanged: _onMenuChanged),
      body: _queryDeviceList()
    );
  }

  /// List devices owned by the authenticated user
  Widget _queryDeviceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('boards')
          .where('owner', isEqualTo: _user.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());
          default:
            return Column(children: snapshot.data.docs.map((DocumentSnapshot data) {
                return Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.developer_board),
                        title: Text(data.id),
                        onTap: () => _selectDevice(context, data),
                      )
                    ],
                  )
                );
              }).toList());
        }
      },
    );
  }

  /// Show user panel to send a device command
  void _selectDevice(BuildContext context, DocumentSnapshot data) {
    print("device selected")
    // showModalBottomSheet(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return DeviceConfigPanel(device: device);
    //   },
    // );
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

    final snackBar = SnackBar(content: Text('Registering device'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}