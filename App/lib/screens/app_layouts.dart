import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/models/track.dart';
import 'home_screen.dart';
import 'playlist_screen.dart';
import '../services/database_service.dart';
import '../models/glass_box.dart';

class AppLayout extends StatefulWidget {
  final DatabaseService dbService;
  String mode;
  final List<Track>? initialTracks;
  AppLayout({super.key, required this.dbService, required this.mode, this.initialTracks});

  final prefs = SharedPreferences.getInstance();

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  final GlobalKey<PlaylistScreenState> playlistKey = GlobalKey<PlaylistScreenState>();
  final GlobalKey<MyHomeScreenState> homeKey = GlobalKey<MyHomeScreenState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double wRatio = size.width / 392.7;
    final double hRatio = size.height / 850.7;

    final List<Widget> screens = [
      MyHomeScreen(key: homeKey, dbService: widget.dbService, mode: widget.mode, initialTracks: widget.initialTracks,),
      PlaylistScreen(key: playlistKey, dbService: widget.dbService, mode: widget.mode, onNotifyUpdate: () => homeKey.currentState?.syncStarsWithLikes()),
    ];

    return Scaffold(
      backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      appBar: AppBar(
        toolbarHeight: 80 * hRatio,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
        title: Image.asset(
          widget.mode == "light" ? 'assets/images/TRACKSTAR sans typo 1.png' : 'assets/images/TRACKSTAR variant sans typo 1.png',
          width: 30 * wRatio,
          height: 30 * wRatio,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.0 * wRatio),
            child: IconButton(
              icon: Icon(
                widget.mode == "light" ? Icons.dark_mode_outlined : Icons.light_mode_rounded,
                color: widget.mode == "light" ? Colors.black : Colors.white,
                size: 24 * wRatio,
              ),
              onPressed: () {
                setState(() {
                  widget.mode = (widget.mode == "light") ? "dark" : "light";
                  widget.prefs.then((prefs) => prefs.setString('theme_mode', widget.mode));
                });
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex, 
        children: screens,
      ),
      bottomNavigationBar: Container(
        color: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
        height: 95 * hRatio,
        alignment: Alignment.topCenter,
        child: GlassBox(
          height: 80 * hRatio,
          borderRadius: BorderRadius.circular(20 * wRatio),
          padding: 6 * wRatio,
          mode: widget.mode,
          child: IntrinsicWidth(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavItem(
                  index: 0,
                  wRatio: wRatio,
                  hRatio: hRatio,
                  iconPath: widget.mode == "light" ? 'assets/images/swipe-icon-black.png' : 'assets/images/swipe-icon-white.png',
                ),
                SizedBox(width: 13 * wRatio),
                _buildNavItem(
                  index: 1,
                  wRatio: wRatio,
                  hRatio: hRatio,
                  iconPath: 'assets/images/playlist-liked-icon-white.png',
                  isPlaylist: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required double wRatio,
    required double hRatio,
    required String iconPath,
    bool isPlaylist = false,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (isPlaylist) playlistKey.currentState?.loadPlaylist();
      },
      child: Container(
        width: 100 * wRatio,
        height: 60 * hRatio,
        decoration: BoxDecoration(
          color: widget.mode == "light" 
              ? (isSelected ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.25)) 
              : (isSelected ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(15 * wRatio),
          border: Border.all(
            color: widget.mode == "light" 
                ? Colors.black.withOpacity(0.14) 
                : Colors.white.withOpacity(0.14),
          ),
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            width: 24 * wRatio,
            color: isPlaylist && widget.mode == "light" ? Colors.black : null,
          ),
        ),
      ),
    );
  }
}
