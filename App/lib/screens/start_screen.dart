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
    _prepareDataAndNavigate();
  }

  Future<void> _prepareDataAndNavigate() async {
    final startTime = DateTime.now();

    try {
      final int interactionCount = await widget.dbService.countInteractions();
      final initialTracks = interactionCount < 5
          ? await widget.dbService.getColdStartTracks(excludeTrackIds: List<String>.empty(growable: true))
          : await widget.dbService.getHybridRecommendations(excludeTrackIds: List<String>.empty(growable: true));

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inSeconds < 2) {
        await Future.delayed(Duration(seconds: 2 - elapsed.inSeconds));
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppLayout(
              dbService: widget.dbService, 
              mode: widget.mode,
              initialTracks: initialTracks,
            ),
          ),
        );
      }
    } catch (e) {
      print("Erreur de chargement: $e");
    }
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
              width: 40,
            ),
          ],
        ),
      ),
    );
  }
}