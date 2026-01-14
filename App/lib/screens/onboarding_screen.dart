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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: PageView(
        children: [
          _buildPage(
            title: "Bienvenue sur TrackStar", 
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
            text: "On commence par 5 morceaux pour calibrer ton profil.",
            icon: Icons.rocket_launch,
            isLast: true,
            onDone: () async {
              await PrefsService.setOnboardingComplete();
              
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AppLayout(dbService: dbService, mode: mode, initialTracks: initialTracks,)),
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
    VoidCallback? onDone
  }) {
    return Padding(
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
              color: mode == "light" ? Colors.black : Colors.white
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: TextStyle(
              fontSize: 16, 
              color: mode == "light" ? Colors.black54 : Colors.white70
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
    );
  }
}