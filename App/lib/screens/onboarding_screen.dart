import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/models/track.dart';
import 'package:trackstar/screens/app_layouts.dart';
import 'package:trackstar/services/prefs_service.dart';

class OnboardingScreen extends StatelessWidget {
  final dynamic dbService;
  final String mode;
  final List<Track>? initialTracks;

  const OnboardingScreen({super.key, required this.dbService, required this.mode, this.initialTracks});

  void _navigateToNext(Widget nextScreen) {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: PageView(
        children: [
          _buildPage(
            title: "Bienvenue sur Trackstar", 
            text: "Découvre de nouveaux sons chaque jour.",
            icon: Icons.music_note,
          ),
          _buildPage(
            title: "Le Geste", 
            text: "Swipe à droite pour Liker, à gauche pour ignorer.",
            icon: Icons.swipe,
          ),
          _buildPage(
            title: "Prêt ?", 
            text: "On commence par 5 titres pour calibrer votre profil.",
            icon: Icons.rocket_launch,
            isLast: true,
            onDone: () async {
              await PrefsService.setOnboardingComplete();
              
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AppLayout(dbService: dbService, mode: mode, initialTracks: initialTracks,),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutQuart;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 1200),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String text,
    required IconData icon,
    bool isLast = false,
    VoidCallback? onDone,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: mode == "light" ? Colors.black : Colors.white),
              const SizedBox(height: 40),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: mode == "light" ? Colors.black : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: mode == "light" ? Colors.black54 : Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              if (isLast) ...[
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mode == "light" ? Colors.black : Colors.white,
                    foregroundColor: mode == "light" ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text("Commencer le test"),
                ),
              ]
            ],
          ),
        ),
        if (!isLast)
          Positioned(
            top: 0,
            bottom: 0,
            right: 20,
            child: Center(
              child: _ScrollingArrow(mode: mode)
            ),
          ),
      ],
    );
  }
}

class _ScrollingArrow extends StatefulWidget {
  final String mode;
  const _ScrollingArrow({required this.mode});

  @override
  State<_ScrollingArrow> createState() => _ScrollingArrowState();
}

class _ScrollingArrowState extends State<_ScrollingArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Container(
            alignment: AlignmentGeometry.centerRight,
            child: Icon(
              Icons.arrow_forward_ios,
              color: widget.mode == "light" ? Colors.black26 : Colors.white24,
              size: 30,
            ),
          )
        );
      },
    );
  }
}