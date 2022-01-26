import 'package:app/utils/authentication.dart';
import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Boards',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/logo.png',
              height: 40,
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon (Icons.logout),
            label: 'Sign out'
          )
        ],
      onTap: (index) async {
        if(index == 2) {
          await Authentication.signOut(context: context);
          const snackBar = SnackBar(content: Text('Signed out'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pushReplacementNamed(context, "/");
        }
      }
    );
  }
}

