import 'package:flutter/material.dart';


// Application title bar

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
            child: Text(title, style: const TextStyle(fontSize: 26),)
        ),
      ],
    );
  }
}