import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackstar/screens/onboarding_screen.dart';
import 'app_layouts.dart';

class SplashScreen extends StatefulWidget {
  final dynamic dbService;
  final String mode;
  final bool startWithOnboarding;
  const SplashScreen({super.key, required this.dbService, required this.mode, required this.startWithOnboarding});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(
      reverse: true,
    ); 

    _animation = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.3, curve: Curves.easeInOut)),
    );

    _prepareDataAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext(Widget nextScreen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
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

      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          if (widget.startWithOnboarding) {
            _navigateToNext(OnboardingScreen(
              dbService: widget.dbService, 
              mode: widget.mode,
              initialTracks: initialTracks,
            ),);
          } else {
            _navigateToNext( AppLayout(
              dbService: widget.dbService, 
              mode: widget.mode,
              initialTracks: initialTracks,
            ),);
          }
        }
      });
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
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                widget.mode == "light" ? 'assets/images/TRACKSTAR sans typo 1.png' : 'assets/images/TRACKSTAR variant sans typo 1.png',
                width: 40,
              ),
            )
          ],
        ),
      ),
    );
  }
}