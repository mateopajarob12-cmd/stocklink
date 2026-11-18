import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const StockLinkApp());
}

class StockLinkApp extends StatelessWidget {
  const StockLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}