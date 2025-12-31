import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/track.dart';
import 'dart:math' as math;

// ========== CONSTANTES ==========
class _CardConstants {
  static const double width = 350;
  static const double height = 450;
  static const double borderRadius = 9;
  static const double swipeThreshold = 100.0;
  static const double maxRotationAngle = 20.0;
  static const double dragRotationDivisor = 500.0;
  static const Duration animationDuration = Duration(milliseconds: 250); // Légèrement augmenté pour la fluidité
  static const double nextCardScale = 0.9;
  static const double nextCardScaleMax = 1.0;
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
  const MyHomeScreen({super.key, required this.dbService});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _currentTrackIndex = 0;
  List<Track> _recommendations = [];
  
  // Utilisation d'un ValueNotifier pour éviter le setState saccadé
  final ValueNotifier<double> _dragXNotifier = ValueNotifier<double>(0.0);
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _CardConstants.animationDuration,
    );
    _fetchHybridRecommendations(isInitial: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dragXNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchHybridRecommendations({bool isInitial = false}) async {
    if (isInitial) setState(() => _isLoading = true);
    final int interactionCount = await widget.dbService.countInteractions();
    final List<Track> tracks = interactionCount < 5 
        ? await widget.dbService.getColdStartTracks() 
        : await widget.dbService.getHybridRecommendations();

    if (mounted) {
      setState(() {
        _recommendations.addAll(tracks);
        _isLoading = false;
      });
    }
  }

  void _onSwipe(bool liked) async {
    if (_recommendations.isEmpty) return;
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentTrackIndex >= _recommendations.length) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentTrack = _recommendations[_currentTrackIndex];
    final nextTrack = (_currentTrackIndex + 1 < _recommendations.length) ? _recommendations[_currentTrackIndex + 1] : null;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 247, 241),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/BACKGROUND2.png', fit: BoxFit.cover)),
          _buildOverlayGradient(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCardStackNotifier(currentTrack, nextTrack),
                  const SizedBox(height: 15),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
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
              const Color.fromARGB(255, 248, 247, 241),
              const Color.fromARGB(255, 248, 247, 241).withOpacity(0.3),
              const Color.fromARGB(255, 248, 247, 241).withOpacity(0.3),
              const Color.fromARGB(255, 248, 247, 241),
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
          child: const Icon(Icons.close, size: 30, color: Colors.black),
        ),
        const SizedBox(width: 150),
        FloatingActionButton(
          heroTag: "likeBtn",
          onPressed: () => _onButtonSwipe(true),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.favorite, size: 30, color: Colors.black),
        ),
      ],
    );
  }
}