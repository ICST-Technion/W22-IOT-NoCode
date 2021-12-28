import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/screens/sign_in_screen.dart';
import 'package:app/utils/authentication.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late User _user;
  bool _isSigningOut = false;

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
    _user = widget._user;

    super.initState();
  }

  Future<void> _onMenuChanged (int index) async {
    if(index == 1) {
      setState(() {
        _isSigningOut = true;
      });

      await Authentication.signOut(context: context);

      setState(() {
        _isSigningOut = false;
      });

      Navigator.of(context).pushReplacement(_routeToSignInScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.firebaseNavy,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CustomColors.firebaseNavy,
        title: AppBarTitle(),
      ),
      bottomNavigationBar: BottomNavbar(onChanged: _onMenuChanged),
    );
  }
}