import 'package:app/screens/boards_screen.dart';
import 'package:app/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT No Code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(),
        '/boards': (context) => BoardsScreen(),
        '/scan': (context) => ScanScreen(),
      },
    );
  }
}