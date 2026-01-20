import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/models/track.dart';
import 'package:trackstar/screens/app_layouts.dart';
import 'package:trackstar/services/prefs_service.dart';

class OnboardingScreen extends StatefulWidget {
  final dynamic dbService;
  final String mode;
  final List<Track>? initialTracks;

  const OnboardingScreen({super.key, required this.dbService, required this.mode, this.initialTracks});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;
  late Animation<double> _glowAnimation;

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _scrollOffset = _pageController.hasClients ? _pageController.page ?? 0 : 0;
      });
    });

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500), 
    )..repeat();

    _heartbeatAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)), 
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), 
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0), 
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOutCubic)), 
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), 
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutCubic)), 
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), 
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0), 
        weight: 40,
      ),
    ]).animate(_heartbeatController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.1), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.2), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.1), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight:40),
    ]).animate(_heartbeatController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double hRatio = size.height / 850.7;
    final double wRatio = size.width / 392.7;

    final starSize = size.width * 1.8;

    return Scaffold(
      backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _heartbeatController,
            builder: (context, child) {
              return Positioned(
                top: (size.height - starSize) / 2,
                left: (size.width / 2) - (starSize / 2) + (size.width * 0.5) - (_scrollOffset * size.width * 0.5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: starSize * 0.7,
                      height: starSize * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (widget.mode == "light" ? Colors.black : Colors.white)
                                .withOpacity(_glowAnimation.value),
                            blurRadius: 60 * _heartbeatAnimation.value * wRatio,
                            spreadRadius: 20 * _heartbeatAnimation.value * wRatio,
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: widget.mode == "light" ? 0.3 : 0.6, 
                      child: Transform.scale(
                        scale: _heartbeatAnimation.value,
                        child: Image.asset(
                          "assets/images/star.png",
                          width: starSize,
                          height: starSize,
                          color: widget.mode == "light" ? Colors.black : Colors.white,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          PageView(
            controller: _pageController,
            children: [
              _buildPage(
                context,
                hRatio, wRatio,
                title: "BIENVENUE SUR TRACKSTAR",
                text: "Chase Stars, Not Trends.\nConstruisez votre propre univers musical.",
                icon: Icons.radar,
              ),
              _buildPage(
                context,
                hRatio, wRatio,
                title: "CHOISISSEZ VOS ÉTOILES",
                text: "Swipe à droite pour garder un titre.\nSwipe à gauche pour l'ignorer.",
                icon: Icons.swipe,
              ),
              _buildPage(
                context,
                hRatio, wRatio,
                title: "AJUSTEZ VOTRE TRAJECTOIRE",
                text: "Analysez quelques étoiles pour stabiliser le système et affiner votre trajectoire musicale.",
                icon: Icons.tune,
                isLast: true,
                onDone: () async {
                  await PrefsService.setOnboardingComplete();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => AppLayout(
                          dbService: widget.dbService,
                          mode: widget.mode,
                          initialTracks: widget.initialTracks,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutQuart;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
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
        ],
      )
    );
  }

  Widget _buildPage(
    BuildContext context,
    double hRatio, double wRatio, {
    required String title,
    required String text,
    required IconData icon,
    bool isLast = false,
    VoidCallback? onDone,
  }) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLast) Spacer(flex: 3),
              
              Icon(
                icon, 
                size: 100 * wRatio, 
                color: widget.mode == "light" ? Colors.black : Colors.white
              ),
              
              SizedBox(height: 40 * hRatio),
              
              Text(
                title,
                style: TextStyle(
                  fontSize: 28 * wRatio,
                  fontWeight: FontWeight.bold,
                  color: widget.mode == "light" ? Colors.black : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 20 * hRatio),
              
              Text(
                text,
                style: TextStyle(
                  fontSize: 16 * wRatio,
                  color: widget.mode == "light" ? Colors.black54 : Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (isLast) ...[
                SizedBox(height: 40 * hRatio),
                ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.mode == "light" ? Colors.black : Colors.white,
                    foregroundColor: widget.mode == "light" ? Colors.white : Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40 * wRatio, vertical: 15 * hRatio),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text("Commencer le test", style: TextStyle(fontSize: 16 * wRatio)),
                ),
                Spacer(flex: 2),
              ]
            ],
          ),
        ),
        if (!isLast)
          Positioned(
            top: 0,
            bottom: 0,
            right: 20 * wRatio,
            child: Center(
              child: _ScrollingArrow(mode: widget.mode, wRatio: wRatio)
            ),
          ),
      ],
    );
  }
}

class _ScrollingArrow extends StatefulWidget {
  final String mode;
  final double wRatio;
  const _ScrollingArrow({required this.mode, required this.wRatio});

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
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 15.0 * widget.wRatio)
            .chain(CurveTween(curve: Curves.easeOut)), 
        weight: 50
      ),
      TweenSequenceItem(
        tween: Tween(begin: 15.0 * widget.wRatio, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)), 
        weight: 50
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = 30 * widget.wRatio;
    final double fontSize = 18 * widget.wRatio;
    final double spacing = 10 * widget.wRatio;
    final double bottomOffset = 80 * widget.wRatio;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_forward_ios,
                color: widget.mode == "light" ? Colors.black26 : Colors.white,
                size: iconSize,
              ),
              SizedBox(height: spacing),
              Text(
                "Swipe",
                style: TextStyle(
                  color: widget.mode == "light" ? Colors.black26 : Colors.white,
                  fontSize: fontSize,
                ),
              ),
              SizedBox(height: bottomOffset),
            ]
          )
        ); 
      },
    );
  }
}