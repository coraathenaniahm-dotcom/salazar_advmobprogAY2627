import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(seconds: 8));

    final loggedIn = await userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await userService.getUserData();
      navigator.pushReplacementNamed('/home', arguments: userData);
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/nubdexchange_logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'NUBD Exchange',
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
