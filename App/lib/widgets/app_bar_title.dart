import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';


class AppBarTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            flex: 1,
            child: Image.asset(
              'assets/app_bar_logo.png',
              height: 40,
              // width: 50,
              // scale: 0.2,
            )
        )
      ],
    );
  }
}