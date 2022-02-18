import 'package:app/utils/authentication.dart';
import 'package:flutter/material.dart';


// Bottom navigation bar

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Boards',
          ),
          BottomNavigationBarItem(
            icon: Icon (Icons.logout),
            label: 'Sign out'
          )
        ],
      onTap: (index) async {

        // If taped on sign out

        if(index == 0) {
          // if the current page is not /boards, navigate to boards
          if(ModalRoute.of(context).settings.name != "/boards") {
            Navigator.pushReplacementNamed(context, "/boards");
          }
        }
        else if(index == 1) {
          await Authentication.signOut(context: context);
          const snackBar = SnackBar(content: Text('Signed out'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pushReplacementNamed(context, "/");
        }
      }
    );
  }
}

