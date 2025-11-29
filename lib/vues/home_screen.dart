import 'package:flutter/material.dart';
import 'dart:math';
import '../models/music.dart';
import 'playlist_screen.dart'; 

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; 
  int _currentMusicIndex = 0;
  double _dragX = 0.0;
  double _startDragX = 0.0;
  late final AnimationController _animationController;
  final double _swipeThreshold = 100.0; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
    ..addListener(() {
      setState(() {
        _dragX = _startDragX * _animationController.value; 
      });
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dragX = 0.0;
          _startDragX = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextCard() {
    setState(() {
      _currentMusicIndex = (_currentMusicIndex + 1) % listeMusiquesRap.length;
      _dragX = 0.0;
      _startDragX = 0.0;
    });
  }

  void _resetCard() {
    _startDragX = _dragX;
    _animationController.reverse(from: 1.0);
  }


  @override
  Widget build(BuildContext context) {
    if (listeMusiquesRap.isEmpty) {
      return const Scaffold(body: Center(child: Text("Aucune musique à afficher")));
    }
    
    final Musique musiqueActuelle = listeMusiquesRap[_currentMusicIndex];
    final int nextIndex = (_currentMusicIndex + 1) % listeMusiquesRap.length;
    final Musique musiqueSuivante = listeMusiquesRap[nextIndex];
    final double dragFactor = (_dragX.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final double angle = _dragX / 250 * 0.2; 
    
    return Scaffold(
      backgroundColor: Colors.yellow.shade100,
      body: Center(
        child: Stack(
            children: <Widget>[
              Transform.scale(
                scale: 0.9 + (dragFactor * 0.1), 
                child: Container(
                  width: 250,
                  height: 350,
                  decoration: BoxDecoration(
                    color: musiqueSuivante.couleur, 
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.grey, blurRadius: 20.0),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        musiqueSuivante.titre + "\n" + musiqueSuivante.artiste,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                
                opacity: 1.0 - dragFactor, 
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _dragX += details.delta.dx;
                    });
                  },
                  onPanEnd: (details) {
                    if (_dragX.abs() > _swipeThreshold) {
                      _nextCard(); 
                    } else {
                      _animationController.value = 1.0;
                      _resetCard();
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(_dragX, 0),
                    child: Transform.rotate( 
                      angle: angle, 
                      child: Container(
                        width: 250,
                        height: 350,
                        decoration: BoxDecoration(
                          color: musiqueActuelle.couleur, 
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.grey, blurRadius: 20.0),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              musiqueActuelle.titre + "\n" + musiqueActuelle.artiste,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.yellow.shade100,
        currentIndex: _selectedIndex, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music_rounded), label: "Playlist"),
        ],
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          
          if (index == 1) {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => const PlaylistScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}