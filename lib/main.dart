import 'package:flutter/material.dart';

import 'login_page.dart';

void main() {
  runApp(const ObsApp());
}

class ObsApp extends StatelessWidget {
  const ObsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YÖKSİS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
