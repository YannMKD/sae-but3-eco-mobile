import 'package:flutter/material.dart';
import 'package:trackstar/models/glass_box.dart';
import '../services/database_service.dart';
import '../models/track.dart';

class PlaylistScreen extends StatefulWidget {
  final DatabaseService dbService;
  final String mode;

  const PlaylistScreen({super.key, required this.dbService, required this.mode});

  @override
  State<PlaylistScreen> createState() => PlaylistScreenState();
}

class PlaylistScreenState extends State<PlaylistScreen> {
  bool _isLoading = true;
  List<Track> _likedTracks = [];

  @override
  void initState() {
    super.initState();
    loadPlaylist();
  }

  Future<void> loadPlaylist() async {    
    final tracks = await widget.dbService.getLikedTracks();
    
    setState(() {
      _likedTracks = tracks;
      _isLoading = false;
    });
  }

  void _onRemove(String trackId) {
    setState(() {
      _likedTracks.removeWhere((track) => track.trackId == trackId);
    });

    widget.dbService.updateInteraction(trackId, 0);

    loadPlaylist();
  }

  void _onRemoveAll() {
    setState(() => _isLoading = true);

    for (Track track in _likedTracks){
      if (track.liked == 1) {
        widget.dbService.updateInteraction(track.trackId, 0);
      }
    }
    
    loadPlaylist();
  }

  void _confirmAndResetLikedTracks(BuildContext context) {
    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
          content: const Text("Êtes-vous sûr de vouloir supprimer toute votre like list ? Cette action est iréversible"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text("Annuler")
            ), 
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onRemoveAll();
              },
              child: const Text("Supprimer tout", style: TextStyle(color: Colors.red)),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.mode == "light" ? Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: Stack(
        children: [
          SafeArea(child: _buildBody(),),
          _buildOverlayGradient(),
        ]
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return IgnorePointer(
      child: Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241) : Colors.black,
              ],
              stops: const [0.0, 0.3, 0.85, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_likedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Pas encore de titres aimés",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              "Swipez à droite pour ajouter des titres !",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Nombre de titres : ${_likedTracks.length}',
                style: TextStyle(fontWeight: FontWeight.bold,  color: widget.mode == "light" ? Colors.black : Colors.white),
                textAlign: TextAlign.left,
              ),
              TextButton.icon(
                onPressed: () => _confirmAndResetLikedTracks(context),
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text(
                  'Supprimer Toute la Liste',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _likedTracks.length,
            separatorBuilder: (context, index) => const Divider(thickness: 0),
            itemBuilder: (context, index) {
              final track = _likedTracks[index];

              return GlassBox(
                width: MediaQuery.of(context).size.width,
                borderRadius: BorderRadius.circular(10),
                padding: 1,
                mode: widget.mode,
                child: IntrinsicHeight(
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    leading: Container(
                      height: 68,
                      width: 68,
                      decoration: BoxDecoration(
                        color: widget.mode == "light" ? Colors.grey[300] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, size: 40, color: Colors.grey),
                    ),
                    title: Text(
                      track.trackName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: widget.mode == "light" ? Colors.black : Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.trackArtist,
                      style: TextStyle(color: widget.mode == "light" ? Colors.grey[700] : Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: widget.mode == "light" ? 
                            const Icon(Icons.delete_outline_outlined, color:  Colors.black):
                            const Icon(Icons.delete_outline_outlined, color:  Colors.white),
                          onPressed: () => _onRemove(track.trackId),
                        ),
                      ],
                    ),
                  ),
                ) 
              );
            }
          )
        )
      ]
    );
  }
}
