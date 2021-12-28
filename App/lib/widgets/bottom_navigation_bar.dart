import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  BottomNavbar({Key? key, required this.onChanged});

  final Function(int)? onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Sign out'
          )
        ],
      onTap: onChanged
    );
  }
}

