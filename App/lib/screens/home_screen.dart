import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/models/glass_box.dart';
import 'package:trackstar/models/star.dart';
import 'package:trackstar/models/starfield_painter.dart';
import 'package:trackstar/models/swipe_icon_particle.dart';
import 'package:trackstar/screens/loading.dart';
import '../services/database_service.dart';
import '../models/track.dart';
import 'dart:math' as math;

class _CardConstants {
  static const double width = 350;
  static const double height = 450;
  static const double borderRadius = 9;
  static const double swipeThreshold = 100.0;
  static const double maxRotationAngle = 20.0;
  static const double dragRotationDivisor = 500.0;
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const double nextCardScale = 0.9;
}

class MyHomeScreen extends StatefulWidget {
  final DatabaseService dbService;
  final String mode;
  final List<Track>? initialTracks;
  const MyHomeScreen({super.key, required this.dbService, required this.mode, this.initialTracks,});

  @override
  State<MyHomeScreen> createState() => MyHomeScreenState();
}

class MyHomeScreenState extends State<MyHomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  int _currentTrackIndex = 0;
  List<Track> _recommendations = [];
  final Set<String> _shownTrackIds = <String>{}; 

  final ValueNotifier<double> _dragXNotifier = ValueNotifier<double>(0.0);

  List<SwipeIconParticle> _swipeParticles = [];
  late AnimationController _particleController;

  Offset? _touchPosition;
  List<Star> _stars = [];

  int _tutoSwipeCount = 0;
  bool _isTutoActive = true;

  bool _tutoIconVisible = true;

  bool _isFetching = false; 

  late AnimationController _masterController;
  late AnimationController _swipeController;

  late Animation<double> _nebulaAnimation;
  late Animation<Offset> _tutoAnimation;

  late double cardWidth;
  late double cardHeight;
  late double swipeThreshold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final double wRatio = size.width / 392.7;
    final double hRatio = size.height / 850.7;

    cardWidth = 350 * wRatio;
    cardHeight = 450 * hRatio;
    swipeThreshold = 100.0 * wRatio;
    
    if (_stars.isEmpty) {
      _stars = List.generate(300, (i) {
        final size = MediaQuery.of(context).size;
        const double margin = 100.0;
        
        final double initialX = (math.Random().nextDouble() * (size.width + 2 * margin)) - margin;
        final double initialY = math.Random().nextDouble() * size.height;
    
        return Star(
          initialX, 
          initialY, 
          widget.mode == "dark" ? math.Random().nextDouble() * 1.0 : math.Random().nextDouble() * 1.0, 
          math.Random().nextDouble(),
          initialX,
          initialY,
        );
      });
    }
    syncStarsWithLikes();
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.initialTracks != null && widget.initialTracks!.isNotEmpty) {
      _recommendations = List.from(widget.initialTracks!);
      _shownTrackIds.addAll(_recommendations.map((t) => t.trackId));
      _isLoading = false;
    } else {
      _fetchHybridRecommendations(isInitial: true);
    }
  
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _nebulaAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeInOut, reverseCurve: Curves.easeInOut),
    );

    _tutoAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.05, 0.0)).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.05, 0.0), end: const Offset(0.05, 0.0)).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(CurvedAnimation(parent: _masterController, curve: const Interval(0.0, 0.5)));

    _frameTimer.reset();
    _frameTimer.start();

    _masterController.addListener(() {
    final now = DateTime.now();
    final touch = _touchPosition;

    int step = _performanceLevel == 0 ? 2 : 1;

    for (int i = 0; i < _stars.length; i += step) {
      var star = _stars[i];

      if (star.isNew && star.birthTime != null) {
        if (now.difference(star.birthTime!).inMilliseconds > 2000) {
          star.isNew = false;
        }
      }

      double targetX = star.originX;
      double targetY = star.originY;

      if (touch != null && _performanceLevel > 0) {
        double dx = star.x - touch.dx;
        double dy = star.y - touch.dy;
        double distSq = dx * dx + dy * dy; 
        
        if (distSq < 10000) { 
          if (_performanceLevel == 2) {
            double dist = math.sqrt(distSq);
            double force = (100 - dist) * 0.5;
            targetX += (dx / dist) * force;
            targetY += (dy / dist) * force;
          } else {
            targetX += dx * 0.05;
            targetY += dy * 0.05;
          }
        }
      }

      star.x += (targetX - star.x) * 0.1;
      star.y += (targetY - star.y) * 0.1;
    }

    _frameTimer.stop();
    _adjustPerformance(_frameTimer.elapsedMilliseconds); 
  });

    _swipeController = AnimationController(vsync: this, duration: _CardConstants.animationDuration);
    _particleController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500)
    )..addListener(() {
        if (_swipeParticles.isNotEmpty) {
          setState(() {
            for (var p in _swipeParticles) {
              p.x += p.vx;
              p.y += p.vy;
              
              p.vx *= 0.82; 
              p.opacity -= 0.06; 
            }
            _swipeParticles.removeWhere((p) => p.opacity <= 0);
          });
        }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _swipeController.dispose();
    _dragXNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchHybridRecommendations({bool isInitial = false}) async {
    if (_isFetching) return;
    
    _isFetching = true;
    if (isInitial) setState(() => _isLoading = true);

    try {
      if (isInitial) setState(() => _isLoading = true);
      final int interactionCount = await widget.dbService.countInteractions();
      final List<Track> tracks = interactionCount < 5
          ? await widget.dbService.getColdStartTracks(excludeTrackIds: _shownTrackIds.toList())
          : await widget.dbService.getHybridRecommendations(excludeTrackIds: _shownTrackIds.toList());

      _shownTrackIds.addAll(tracks.map((t) => t.trackId));

      if (mounted) {
        setState(() {
          _recommendations.addAll(tracks);
          _isLoading = false;
        });
      }
    } catch (e){
      debugPrint("Erreur de chargement: $e");
    } finally {
      _isFetching = false;
    }
  }

  int _performanceLevel = 2; 
  Stopwatch _frameTimer = Stopwatch();

  void _adjustPerformance(int frameTimeMs) {
    if (frameTimeMs > 25 && _performanceLevel > 0) {
      setState(() => _performanceLevel--);
    } else if (frameTimeMs < 10 && _performanceLevel < 2) {
      setState(() => _performanceLevel++);
    }
  }

  void _onSwipe(bool liked) async {
    if (_recommendations.isEmpty || _currentTrackIndex >= _recommendations.length) {
      return;
    }

    _spawnSwipeParticles(liked);

    setState(() => _tutoIconVisible = false);

    Timer(const Duration(seconds: 10), () {
      if (mounted && _isTutoActive) {
        setState(() => _tutoIconVisible = true);
      }
    });

    if (liked) {
      syncStarsWithLikes();
    }

    if (_isTutoActive) {
      _tutoSwipeCount++;
      if (_tutoSwipeCount >= 5) {
        setState(() {
          _isTutoActive = false;
          _tutoIconVisible = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tuto_swipes_done', true);
        _showTutoConclusion();
      }
    }

    await widget.dbService.updateInteraction(_recommendations[_currentTrackIndex].trackId, liked ? 1 : -1);

    setState(() {
      _currentTrackIndex++;
      _dragXNotifier.value = 0.0;
    });

    if (_recommendations.length - _currentTrackIndex <= 3) {
      _fetchHybridRecommendations();
    }
  }

  Future<void> syncStarsWithLikes() async {
    if (_recommendations.isEmpty || _currentTrackIndex >= _recommendations.length) return;
  
    final likedTracks = await widget.dbService.getLikedTracks();

    setState(() {
      for (var star in _stars) {
        star.color = Colors.white;
      }

      if (likedTracks.isEmpty) return;

      Map<String, int> counts = {};
      for (var t in likedTracks) {
        counts[t.clusterStyle] = (counts[t.clusterStyle] ?? 0) + 1;
      }

      double fillFactor = (likedTracks.length * 0.02).clamp(0.0, 0.9);
      int starsToColor = (_stars.length * fillFactor).toInt();

      int coloredCount = 0;
      counts.forEach((style, count) {
        double ratio = count / likedTracks.length;
        int amountForStyle = (starsToColor * ratio).toInt();
        Color col = getGalaxyColor(style);

        for (int i = 0; i < amountForStyle; i++) {
          if (coloredCount < _stars.length) {
            _stars[coloredCount].color = col;
            coloredCount++;
          }
        }
      });
    });
  }

  void _showTutoConclusion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 248) : const Color.fromARGB(255, 12, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white), "Très bien !"),
        content: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black45 : const Color.fromARGB(107, 255, 255, 255)), "Les paramétrages sont terminés. Nous vous recommanderons désormais des sources selon vos nouvelles préférences !"),
        actions: [
          TextButton(
            style: ButtonStyle(
                padding:MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(horizontal: 20, vertical: 0)),
                side: MaterialStateProperty.all<BorderSide>(BorderSide(color: widget.mode == "light" ? Colors.black38 : const Color.fromARGB(106, 255, 255, 255))),
                foregroundColor: MaterialStateProperty.all<Color>(widget.mode == "light" ? Colors.black : Colors.white),
            ),
            onPressed: () => Navigator.pop(context), child: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white), "Commencer")
          )
        ],
      ),
    );
  }

  void _resetCard() {
    final double startX = _dragXNotifier.value;
    final Animation<double> resetAnim = Tween<double>(begin: startX, end: 0.0)
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack));

    resetAnim.addListener(() => _dragXNotifier.value = resetAnim.value);
    _swipeController.forward(from: 0.0);
  }

  void _animateAndCompleteSwipe(bool liked) {
    final double startX = _dragXNotifier.value;
    final double targetX = liked ? 1000.0 : -1000.0;

    final Animation<double> swipeAnim = Tween<double>(begin: startX, end: targetX)
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeIn));

    swipeAnim.addListener(() => _dragXNotifier.value = swipeAnim.value);
    _swipeController.forward(from: 0.0).then((_) => _onSwipe(liked));
  }

  Color getGalaxyColor(String genre) {
    switch (genre) {
      case 'Musique Calme & Instrumentale': return widget.mode == "light" ? const Color.fromARGB(255, 24, 106, 173).withOpacity(0.8) : const Color.fromARGB(255, 19, 81, 132).withOpacity(0.8);
      case 'Hip-Hop / Électro Rythmé': return widget.mode == "light" ? const Color.fromARGB(255, 170, 102, 0).withOpacity(0.8) : Colors.orange.withOpacity(0.8);
      case 'Danse / Électronique Mélancolique': return widget.mode == "light" ? const Color.fromARGB(255, 95, 24, 107).withOpacity(0.8) : Colors.purple.withOpacity(0.8);
      case 'Rock / Pop Standar': return widget.mode == "light" ? const Color.fromARGB(255, 134, 37, 30).withOpacity(0.8) : Colors.red.withOpacity(0.8);
      case 'Musique Triste / Indépendante': return widget.mode == "light" ? const Color.fromARGB(255, 59, 76, 84).withOpacity(0.8) : Colors.blueGrey.withOpacity(0.8);
      case 'Pop Radio / Joyeuse & Dansante': return widget.mode == "light" ? const Color.fromARGB(255, 138, 128, 32).withOpacity(0.8) : Colors.yellow.withOpacity(0.8);
      default: return Colors.transparent;
    }
  }

  Color getGalaxyStarColor(String genre, String mode) {
    Color base = getGalaxyColor(genre); 
    
    if (mode == "light") {
      return base.withOpacity(1.0); 
    }
    return base;
  }

  void _onButtonSwipe(bool liked) => _animateAndCompleteSwipe(liked);

  void _spawnSwipeParticles(bool liked) {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    
    setState(() {
      for (int i = 0; i < 8; i++) {
        double startX = liked ? size.width : 0; 
        double startY = random.nextDouble() * size.height * 0.6 + size.height * 0.2;
        
        double vx = liked ? -(random.nextDouble() * 12 + 9) : (random.nextDouble() * 12 + 9);

        _swipeParticles.add(SwipeIconParticle(
          isLike: liked,
          x: startX,
          y: startY - size.height * 0.2,
          vx: vx,
          vy: 0,
          angle: liked ? -(math.pi / 2) : (math.pi / 2), 
          size: random.nextDouble() * 10 + 25,
        ));
      }
    });
    _particleController.repeat();
  }

  Widget _buildTutoOverlay() {
    if (!_isTutoActive) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _masterController, 
          builder: (context, child) {
            return FractionalTranslation(
              translation: _tutoAnimation.value, 
              child: Opacity(
                opacity: _tutoIconVisible ? 0.6 : 0.0,
                child: Center(
                  child: Icon(Icons.touch_app, size: 50, color: widget.mode == "light" ? Colors.black : Colors.white24),
                ),
              ),
            );
          },
        ),
      )
    );
  }

  Widget _buildTrackCard(Track track) {
    final size = MediaQuery.of(context).size;
    final double wRatio = size.width / 392.7;

    return GlassBox(
      mode: widget.mode,
      width: cardWidth, 
      height: cardHeight, 
      padding: 0,
      borderRadius: BorderRadius.circular(9 * wRatio),
      child: Stack(
        children: [
          Positioned(
            top: 40 * wRatio, 
            right: 40 * wRatio,
            child: FrequencyScanner(color: widget.mode == "light" ? Colors.black12 : Colors.white24, wRatio: wRatio), 
          ),
          Padding(
            padding: EdgeInsets.all(20 * wRatio),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(track.trackName, style: TextStyle(
                  fontSize: 32 * wRatio,
                  fontWeight: FontWeight.bold,
                  color: widget.mode == "light" ? Colors.black : Colors.white,
                ), maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 5 * wRatio),
                Text(track.trackArtist, style: TextStyle(
                  fontSize: 18 * wRatio,
                  color: widget.mode == "light" ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w300,
                )),
              ],
            ),
          ) 
        ],
      ) 
    );
  }
  
  Widget _buildNebulaBackground(String genre) {
    return AnimatedBuilder(
      animation: _nebulaAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2 * _nebulaAnimation.value, 
              colors: [
                widget.mode == "dark" ? getGalaxyColor(genre).withOpacity(0.2 * _nebulaAnimation.value) : getGalaxyColor(genre).withOpacity(0.8 * _nebulaAnimation.value),
                widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241).withOpacity(0.0) : Colors.black.withOpacity(0.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentralContent(bool isOutOfBounds) {
    if (_isLoading || isOutOfBounds) return Center(child: Loading(color: widget.mode == "light" ? Colors.black : Colors.white, size: 60));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCardStackNotifier(_recommendations[_currentTrackIndex], 
            (_currentTrackIndex + 1 < _recommendations.length) ? _recommendations[_currentTrackIndex + 1] : null),
        const SizedBox(height: 15),
        _buildActionButtons(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOutOfBounds = _currentTrackIndex >= _recommendations.length;

    String currentGenre = (!isOutOfBounds) 
        ? _recommendations[_currentTrackIndex].clusterStyle 
        : "default";

    return Scaffold(
      backgroundColor: widget.mode == "light" 
          ? const Color.fromARGB(255, 248, 247, 241) 
          : Colors.black,
      body: Listener(
        onPointerMove: (e) => _touchPosition = e.localPosition,
        onPointerUp: (e) => _touchPosition = null,
        child: GestureDetector(
          onPanStart: (_) => _masterController.stop(),
          onPanEnd: (_) => _masterController.repeat(),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _masterController,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          _buildNebulaBackground(currentGenre),
                          CustomPaint(painter: StarFieldPainter(_stars, widget.mode)),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _buildOverlayGradient(),
              SafeArea(
                child: RepaintBoundary( 
                  child: _buildCentralContent(isOutOfBounds),
                ),
              ),
                ..._swipeParticles.map((p) => Positioned(
                left: p.x,
                top: p.y,
                child: Opacity(
                  opacity: p.opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: p.angle, 
                    child: Image.asset(
                      !p.isLike 
                        ? 'assets/images/cross-icon-fill-white.png'
                        : 'assets/images/liked-icon-fill-white.png',
                      width: p.size,
                      height: p.size,
                      color: !p.isLike
                        ? (widget.mode == "dark" ? Colors.white : Colors.red)
                        : (widget.mode == "dark" ? Colors.white : Colors.deepPurple),
                    ),
                  ),
                ),
              )).toList(),
              _buildTutoOverlay(),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildCardStackNotifier(Track current, Track? next) {
    return ValueListenableBuilder<double>(
      valueListenable: _dragXNotifier,
      builder: (context, dragX, child) {
        final dragFactor = (dragX.abs() / _CardConstants.swipeThreshold).clamp(0.0, 1.0);
        final angle = (dragX / _CardConstants.dragRotationDivisor) * (math.pi / 180 * _CardConstants.maxRotationAngle);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            if (next != null)
              Opacity(
                opacity: (dragFactor * 1.0).clamp(0.0, 1.0), 
                child: Transform.scale(
                  scale: _CardConstants.nextCardScale + (dragFactor * (1.0 - _CardConstants.nextCardScale)),
                  child: _buildTrackCard(next),
                ),
              ),
              
              GestureDetector(
                onPanStart: (_) => _swipeController.stop(),
                onPanUpdate: (d) => _dragXNotifier.value += d.delta.dx,
                onPanEnd: (_) {
                  if (_dragXNotifier.value.abs() > _CardConstants.swipeThreshold) {
                    _animateAndCompleteSwipe(_dragXNotifier.value > 0);
                  } else {
                    _resetCard();
                  }
                },
                child: Transform.translate(
                  offset: Offset(dragX, 0),
                  child: Transform.rotate(
                    angle: angle,
                    child: _buildTrackCard(current),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
              widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241).withOpacity(0.0) : Colors.black.withOpacity(0.0),
              widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241).withOpacity(0.0) : Colors.black.withOpacity(0.0),
              widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
            ],
            stops: const [0.0, 0.15, 0.85, 1.0],
          ),
        ),
      ),
    );
  }

  bool _isFavorite = false;
  bool _isDisliked = false;

  Widget _buildActionButtons() {
    final size = MediaQuery.of(context).size;
    final double wRatio = size.width / 392.7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GlassBox(
          mode: widget.mode, 
          borderRadius: BorderRadius.circular(20 * wRatio), 
          padding: 5 * wRatio,
          child: SizedBox(
            width: 56 * wRatio, 
            height: 56 * wRatio,
            child: FloatingActionButton(
              heroTag: "dislikeBtn",
              onPressed: () {
                setState(() => _isDisliked = true); 
                Timer(const Duration(milliseconds: 400), () {
                  if (mounted) setState(() => _isDisliked = false);
                });
                _onButtonSwipe(false);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Image.asset(
                !_isDisliked 
                  ? 'assets/images/cross-icon-white.png' 
                  : 'assets/images/cross-icon-fill-white.png', 
                width: 42 * wRatio, 
                color: !_isDisliked
                  ? (widget.mode == "light" ? Colors.black : Colors.white)
                  : (widget.mode == "light" ? Colors.red : Colors.white),
              ),
            ),
          ),
        ),
        
        SizedBox(width: 150 * wRatio), 
        
        GlassBox(
          mode: widget.mode, 
          borderRadius: BorderRadius.circular(20 * wRatio), 
          padding: 5 * wRatio,
          child: SizedBox(
            width: 56 * wRatio,
            height: 56 * wRatio,
            child: FloatingActionButton(
              heroTag: "likeBtn",
              onPressed: () {
                setState(() => _isFavorite = true);
                Timer(const Duration(milliseconds: 400), () {
                  if (mounted) setState(() => _isFavorite = false);
                });
                _onButtonSwipe(true);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Image.asset(
                !_isFavorite 
                  ? 'assets/images/liked-icon-white.png' 
                  : 'assets/images/liked-icon-fill-white.png',
                width: 60 * wRatio, 
                color: !_isFavorite
                  ? (widget.mode == "light" ? Colors.black : Colors.white)
                  : (widget.mode == "light" ? Colors.deepPurple : Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FrequencyScanner extends StatefulWidget {
  final Color color;
  final double wRatio; 
  const FrequencyScanner({super.key, required this.color, required this.wRatio});

  @override
  State<FrequencyScanner> createState() => _FrequencyScannerState();
}

class _FrequencyScannerState extends State<FrequencyScanner> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (i) => AnimationController(
      duration: Duration(milliseconds: 400 + (i * 100)),
      vsync: this,
    )..repeat(reverse: true));

    _animations = _controllers.map((c) => Tween<double>(begin: 2.0, end: 15.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => AnimatedBuilder(
        animation: _animations[i],
        builder: (context, child) => Container(
          margin: EdgeInsets.symmetric(horizontal: 1 * widget.wRatio),
          width: 3 * widget.wRatio, 
          height: _animations[i].value * widget.wRatio,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2 * widget.wRatio),
          ),
        ),
      )),
    );
  }
}


class StarAnimation {
  Offset position;
  double progress = 0.0;
  Color color;
  StarAnimation(this.position, this.color);
}