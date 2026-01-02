import 'dart:async';
import 'package:flutter/material.dart';
import 'app_layouts.dart';

class SplashScreen extends StatefulWidget {
  final dynamic dbService;
  final String mode;
  const SplashScreen({super.key, required this.dbService, required this.mode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppLayout(dbService: widget.dbService, mode:widget.mode),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.mode == "light"  ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              widget.mode == "light" ? 'assets/images/TRACKSTAR sans typo 1.png' : 'assets/images/TRACKSTAR variant sans typo 1.png',
              width: 80,
            ),
          ],
        ),
      ),
    );
  }
}