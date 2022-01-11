import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({Key key, this.onChanged}) : super(key: key);

  final Function(int) onChanged;

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
      onTap: onChanged
    );
  }
}

