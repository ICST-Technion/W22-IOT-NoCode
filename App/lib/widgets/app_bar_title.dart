import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';


class AppBarTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/firebase_logo.png',
          height: 20,
        ),
        SizedBox(width: 8),
        Text(
          'IOT',
          style: TextStyle(
            color: CustomColors.yellow,
            fontSize: 18,
          ),
        ),
        Text(
          ' No Code',
          style: TextStyle(
            color: CustomColors.orange,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}