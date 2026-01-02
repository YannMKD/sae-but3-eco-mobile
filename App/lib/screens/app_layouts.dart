import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'playlist_screen.dart';
import '../services/database_service.dart';
import '../models/glass_box.dart';

class AppLayout extends StatefulWidget {
  final DatabaseService dbService;
  String mode;
  AppLayout({super.key, required this.dbService, required this.mode});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  final GlobalKey<PlaylistScreenState> playlistKey = GlobalKey<PlaylistScreenState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MyHomeScreen(dbService: widget.dbService, mode: widget.mode),
      PlaylistScreen(key: playlistKey, dbService: widget.dbService, mode: widget.mode),
    ];

    return Scaffold(
      extendBody: false,
      backgroundColor: widget.mode=="light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: widget.mode=="light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
        title: Image.asset(
          widget.mode == "light" ? 'assets/images/TRACKSTAR sans typo 1.png' : 'assets/images/TRACKSTAR variant sans typo 1.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(
                widget.mode == "light" ? Icons.dark_mode_outlined : Icons.light_mode_rounded,
                color: widget.mode == "light" ? Colors.black : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  widget.mode = (widget.mode == "light") ? "dark" : "light";
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
        color: widget.mode=="light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
        height: 103,
        alignment: AlignmentGeometry.topCenter,
        child: GlassBox(
          height: 80,
          borderRadius: BorderRadius.circular(20),
          padding: 6,
          mode: widget.mode,
          child: IntrinsicWidth(
            child : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.mode == "light" 
                          ? 
                            (_selectedIndex == 0
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.25)) 
                          :
                            (_selectedIndex == 0
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.25)) ,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: widget.mode=="light" ? 
                        Colors.black.withValues(alpha: 0.14) : 
                        Colors.white.withValues(alpha: 0.14)
                      ),
                    ),
                    child: Center(
                      child: Image.asset(widget.mode == "light" ?
                          'assets/images/swipe-icon-black.png'  :
                          'assets/images/swipe-icon-white.png', 
                        width: 24),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    playlistKey.currentState?.loadPlaylist();
                  },
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                     color: widget.mode == "light" ? 
                          (_selectedIndex == 1
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.25)) :
                          (_selectedIndex == 1
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.25)) ,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: widget.mode=="light" ? 
                        Colors.black.withValues(alpha: 0.14) : 
                        Colors.white.withValues(alpha: 0.14)
                      )
                    ),
                    child: Center(
                      child: Image.asset(
                        widget.mode == "light" ? 
                          'assets/images/playlist-liked-icon-black.png' :
                          'assets/images/playlist-liked-icon-white.png', 
                        width: 24),
                    ),
                  ),
                ),
              ].expand((widget) => [
                widget,
                const SizedBox(width: 13),
              ]).toList()..removeLast(),
            )
          ) 
        ),
      ),
    );
  }
}
