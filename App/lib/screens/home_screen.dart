import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/models/glass_box.dart';
import 'package:trackstar/models/star.dart';
import 'package:trackstar/models/starfield_painter.dart';
import 'package:trackstar/models/swipe_icon_particle.dart';
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

class _TextStyles {
  static final artistStyle = TextStyle(
    fontSize: 18,
    color: Colors.white70,
    fontWeight: FontWeight.w300,
  );
  static const titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const infoStyle = TextStyle(
    fontSize: 14,
    color: Colors.white60,
  );
}

class _Colors {
  static final cardBackground = Colors.blueGrey.shade700;
}

class MyHomeScreen extends StatefulWidget {
  final DatabaseService dbService;
  final String mode;
  final List<Track>? initialTracks;
  const MyHomeScreen({super.key, required this.dbService, required this.mode, this.initialTracks,});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  int _currentTrackIndex = 0;
  List<Track> _recommendations = [];
  final Set<String> _shownTrackIds = <String>{}; 

  final ValueNotifier<double> _dragXNotifier = ValueNotifier<double>(0.0);
  late final AnimationController _animationController;
  late AnimationController _starController;

  List<SwipeIconParticle> _swipeParticles = [];
  late AnimationController _particleController;

  Offset? _touchPosition;
  List<Star> _stars = [];

  int _tutoSwipeCount = 0;
  bool _isTutoActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty) {
      final size = MediaQuery.of(context).size;
      _stars = List.generate(1500, (i) { 
        final size = MediaQuery.of(context).size;
        const double margin = 100.0;
        
        final double initialX = (math.Random().nextDouble() * (size.width + 2 * margin)) - margin;
        final double initialY = math.Random().nextDouble() * size.height;
    
        return Star(
          initialX, 
          initialY, 
          math.Random().nextDouble() * 1.5, 
          math.Random().nextDouble(),
          initialX,
          initialY,
        );
      });
    }
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
  
    _starController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
    ..addListener(() {
      setState(() {
        final size = MediaQuery.of(context).size;
        final double w = size.width;
        
        const double margin = 250.0;
        final double worldWidth = w + 2 * margin;

        for (var star in _stars) {
          star.originX += star.velocityX;

          if (star.originX < -margin) {
            star.originX += worldWidth;
            star.x += worldWidth;
          } else if (star.originX > w + margin) {
            star.originX -= worldWidth;
            star.x -= worldWidth;
          }

          star.velocityX *= 0.4; 

          star.angle += 0.005;
          star.originX += math.cos(star.angle) * 0.05;
          star.originY += math.sin(star.angle) * 0.05;
        }
      });
    })
    ..repeat();

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

    _animationController = AnimationController(
      vsync: this,
      duration: _CardConstants.animationDuration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starController.dispose();
    _dragXNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchHybridRecommendations({bool isInitial = false}) async {
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
  }

  void _onSwipe(bool liked) async {
    if (_recommendations.isEmpty) return;

    _spawnSwipeParticles(liked);

    if (_isTutoActive) {
      _tutoSwipeCount++;
      if (_tutoSwipeCount >= 5) {
        setState(() => _isTutoActive = false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tuto_swipes_done', true);
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

  void _showTutoConclusion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tuto terminé !"),
        content: Text("Tu as compris le principe des swipes. Amuse-toi bien à découvrir de nouveaux morceaux !"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("C'est parti"))
        ],
      ),
    );
  }

  void _resetCard() {
    final double startX = _dragXNotifier.value;
    final Animation<double> resetAnim = Tween<double>(begin: startX, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    resetAnim.addListener(() => _dragXNotifier.value = resetAnim.value);
    _animationController.forward(from: 0.0);
  }

  void _animateAndCompleteSwipe(bool liked) {
    final double startX = _dragXNotifier.value;
    final double targetX = liked ? 1000.0 : -1000.0;

    final Animation<double> swipeAnim = Tween<double>(begin: startX, end: targetX)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    swipeAnim.addListener(() => _dragXNotifier.value = swipeAnim.value);
    _animationController.forward(from: 0.0).then((_) => _onSwipe(liked));
  }

  void _onButtonSwipe(bool liked) => _animateAndCompleteSwipe(liked);

  void _spawnSwipeParticles(bool liked) {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    
    setState(() {
      for (int i = 0; i < 20; i++) {
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

    return IgnorePointer(
      child : Positioned.fill(
        child : Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                "Swipe pour commencer (${5 - _tutoSwipeCount} restants)",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildTrackCard(Track track) {
    return Container(
      width: _CardConstants.width,
      height: _CardConstants.height,
      decoration: BoxDecoration(
        color: _Colors.cardBackground,
        borderRadius: BorderRadius.circular(_CardConstants.borderRadius),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(track.trackName, style: _TextStyles.titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text(track.trackArtist, style: _TextStyles.artistStyle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget centralContent;

    if (_isLoading || _currentTrackIndex >= _recommendations.length) {
      centralContent = Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.mode == "light" ? Colors.black : Colors.white,
          ),
        ),
      );
    } else {
      final currentTrack = _recommendations[_currentTrackIndex];
      final nextTrack = (_currentTrackIndex + 1 < _recommendations.length) 
          ? _recommendations[_currentTrackIndex + 1] 
          : null;

      centralContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCardStackNotifier(currentTrack, nextTrack),
          const SizedBox(height: 15),
          _buildActionButtons(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: widget.mode == "light" 
          ? const Color.fromARGB(255, 248, 247, 241) 
          : Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) => setState(() => _touchPosition = e.localPosition),
        onPointerUp: (e) => setState(() => _touchPosition = null),
        onPointerCancel: (e) => setState(() => _touchPosition = null),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: StarFieldPainter(_touchPosition, _stars, widget.mode),
              ),
            ),
            _buildOverlayGradient(),
            SafeArea(
              child: centralContent,
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
                      ? (widget.mode == "light" 
                          ? 'assets/images/cross-icon-fill-black.png' 
                          : 'assets/images/cross-icon-fill-white.png')
                      : (widget.mode == "light" 
                          ? 'assets/images/liked-icon-fill-black.png' 
                          : 'assets/images/liked-icon-fill-white.png'),
                    width: p.size,
                    height: p.size,
                  ),
                ),
              ),
            )).toList(),
            _buildTutoOverlay()
          ],
        ),
      ),
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
              Transform.scale(
                scale: _CardConstants.nextCardScale + (dragFactor * (1.0 - _CardConstants.nextCardScale)),
                child: _buildTrackCard(next),
              ),
            GestureDetector(
              onPanStart: (_) => _animationController.stop(),
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
              widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
              widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
              widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241) : Colors.black,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GlassBox(
          mode: widget.mode, 
          borderRadius: BorderRadius.circular(20), 
          padding: 5,
          child: FloatingActionButton(
            heroTag: "dislikeBtn",
            onPressed: () {
              _isDisliked = true;
              Timer(const Duration(milliseconds: 400), () {
                _isDisliked = false;
              });

              _onButtonSwipe(false);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            child: Image.asset(
              widget.mode == "light" ? 
                (!_isDisliked 
                  ? 'assets/images/cross-icon-black.png' 
                  : 'assets/images/cross-icon-fill-black.png') :
                (!_isDisliked 
                  ? 'assets/images/cross-icon-white.png' 
                  : 'assets/images/cross-icon-fill-white.png'), 
              width: 42),
          ),
        ),
        const SizedBox(width: 150),
        GlassBox(
          mode: widget.mode, 
          borderRadius: BorderRadius.circular(20), 
          padding: 5,
          child: FloatingActionButton(
            heroTag: "likeBtn",
            onPressed: () {
              _isFavorite = true;
              Timer(const Duration(milliseconds: 400), () {
                _isFavorite = false;
              });

              _onButtonSwipe(true);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
            child: Image.asset(
              widget.mode == "light" ? 
                (!_isFavorite 
                  ? 'assets/images/liked-icon-black.png' 
                  : 'assets/images/liked-icon-fill-black.png') :
                (!_isFavorite 
                  ? 'assets/images/liked-icon-white.png' 
                  : 'assets/images/liked-icon-fill-white.png'), 
              width: 60),
          ),
        ),
      ],
    );
  }
}
