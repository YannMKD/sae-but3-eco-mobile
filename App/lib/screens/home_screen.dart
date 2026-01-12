import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/star.dart';
import 'package:flutter_application_1/models/starfield_painter.dart';
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

  Offset? _touchPosition;
  List<Star> _stars = [];

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
  
  _starController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))
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

          if (!_isWarping) {
            star.velocityX *= 0.4; 

            star.angle += 0.005;
            star.originX += math.cos(star.angle) * 0.05;
            star.originY += math.sin(star.angle) * 0.05;
          }
        }
      });
    })
    ..repeat();

    _animationController = AnimationController(
      vsync: this,
      duration: _CardConstants.animationDuration,
    );
  }

  bool _showLikeOverlay = false;
  bool _showDislikeOverlay = false;

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

  bool _isWarping = false;

  void _triggerStarWarp(bool liked) {
  double force = liked ? 400.0 : -400.0; 

  setState(() {
    _isWarping = true;
    for (var star in _stars) {
      star.velocityX = force * (math.Random().nextDouble() * 1.5 + 1.0);
    }
  });

  Future.delayed(const Duration(milliseconds: 80), () {
    if (mounted) {
      setState(() => _isWarping = false);
    }
  });
}

  void _onSwipe(bool liked) async {
    if (_recommendations.isEmpty) return;

    _triggerStarWarp(liked);

    setState(() {
      if (liked) _showLikeOverlay = true;
      else _showDislikeOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showLikeOverlay = false;
          _showDislikeOverlay = false;
        });
      }
    });

    await widget.dbService.updateInteraction(_recommendations[_currentTrackIndex].trackId, liked ? 1 : -1);

    setState(() {
      _currentTrackIndex++;
      _dragXNotifier.value = 0.0;
    });

    if (_recommendations.length - _currentTrackIndex <= 3) {
      _fetchHybridRecommendations();
    }
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

  Widget _buildSwipeOverlay({required bool isLike}) {
    return Positioned(
      left: isLike ? null : 0,
      right: isLike ? 0 : null,
      top: 0,
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.1,
        decoration: BoxDecoration(
          color: isLike ? Colors.grey.withOpacity(0.45) : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(isLike ? MediaQuery.of(context).size.height /2 : 0), topRight: Radius.circular(isLike ? 0 : MediaQuery.of(context).size.height /2), bottomLeft: Radius.circular(isLike ? MediaQuery.of(context).size.height /2 : 0), bottomRight: Radius.circular(isLike ? 0 : MediaQuery.of(context).size.height /2)),
        ),
        child: Center(
          child: Icon(
            isLike ? Icons.favorite : Icons.close,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
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
            const SizedBox(height: 5),
            Text('Style: ${track.clusterStyle}', style: _TextStyles.infoStyle),
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

            if (_showLikeOverlay) _buildSwipeOverlay(isLike: true),
            if (_showDislikeOverlay) _buildSwipeOverlay(isLike: false),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FloatingActionButton(
          heroTag: "dislikeBtn",
          onPressed: () => _onButtonSwipe(false),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child:  widget.mode == "light" ? 
            const Icon(Icons.close, size: 30, color:  Colors.black) : 
            const Icon(Icons.close, size: 30, color:  Colors.white),
        ),
        const SizedBox(width: 150),
        FloatingActionButton(
          heroTag: "likeBtn",
          onPressed: () => _onButtonSwipe(true),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: widget.mode == "light" ? 
            const Icon(Icons.favorite, size: 30, color:  Colors.black) : 
            const Icon(Icons.favorite, size: 30, color:  Colors.white),
        ),
      ],
    );
  }
}
