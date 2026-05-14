import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/user_credentials_repository.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _sessionResolved;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _refreshSession(initial: true);
  }

  Future<void> _refreshSession({bool initial = false}) async {
    bool v = false;
    try {
      v = await UserCredentialsRepository.instance.isLoggedIn();
    } on Object catch (_) {
      v = false;
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = v;
      if (initial) _sessionResolved = true;
    });
  }

  void _onSignedIn() {
    if (mounted) setState(() => _loggedIn = true);
  }

  Future<void> _onSignedOut() async {
    await UserCredentialsRepository.instance.setLoggedIn(false);
    if (mounted) setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionResolved != true) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loggedIn) {
      return HomePage(onLogout: _onSignedOut);
    }
    return LoginPage(onSignedIn: _onSignedIn);
  }
}
