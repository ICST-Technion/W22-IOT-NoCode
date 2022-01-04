import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  BottomNavbar({Key key, this.onChanged});

  final Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
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
          BottomNavigationBarItem(
            icon: Icon (Icons.logout),
            label: 'Sign out'
          )
        ],
      onTap: onChanged
    );
  }
}

