import 'package:app/screens/board_screen.dart';
import 'package:app/screens/boards_screen.dart';
import 'package:app/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';

// Application entry point
void main() {
  runApp(const MyApp());
}

// Application widget
class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

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
        '/': (context) => const SignInScreen(),
        '/boards': (context) => const BoardsScreen(title: "Boards"),
        '/board': (context) => const BoardScreen(title: "Board"),
        '/scan': (context) => const ScanScreen(title: "Scan"),
      },
    );
  }
}