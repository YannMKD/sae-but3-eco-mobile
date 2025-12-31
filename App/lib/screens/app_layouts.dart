import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'playlist_screen.dart';
import '../services/database_service.dart';
import '../models/glass_box.dart';

class AppLayout extends StatefulWidget {
  final DatabaseService dbService;
  const AppLayout({super.key, required this.dbService});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  final GlobalKey<PlaylistScreenState> playlistKey = GlobalKey<PlaylistScreenState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MyHomeScreen(dbService: widget.dbService),
      PlaylistScreen(key: playlistKey, dbService: widget.dbService),
    ];

    return Scaffold(
      extendBody: false,
      backgroundColor: const Color.fromARGB(255, 248, 247, 241),
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color.fromARGB(255, 248, 247, 241),
        title: Center(
          child: Image.asset(
            'assets/images/TRACKSTAR sans typo 1.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 248, 247, 241),
        padding: const EdgeInsets.fromLTRB(50, 20, 50, 20),
        child: GlassBox(
          width: MediaQuery.of(context).size.width,
          height: 94,
          borderRadius: BorderRadius.circular(20),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1) playlistKey.currentState?.loadPlaylist();
              },
              items: [
                BottomNavigationBarItem(
                  label: "Accueil",
                  icon: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.14), width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: Center(
                      child: Image.asset(
                        'assets/images/swipe-icon-black.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
                BottomNavigationBarItem(
                  label: "Playlist",
                  icon: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.14), width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: Center(
                      child: Image.asset(
                        'assets/images/playlist-liked-icon-black.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
