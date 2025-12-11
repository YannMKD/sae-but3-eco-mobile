import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/track.dart';

class PlaylistScreen extends StatefulWidget {
  final DatabaseService dbService;
  
  const PlaylistScreen({super.key, required this.dbService});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isLoading = true;
  List<Track> _likedTracks = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() => _isLoading = true);
    
    final tracks = await widget.dbService.getLikedTracks();
    
    setState(() {
      _likedTracks = tracks;
      _isLoading = false;
    });
  }

  void _onRemove(String trackId) {
    for (Track track in _likedTracks){
      if (trackId == track.trackId) {
        widget.dbService.updateInteraction(trackId, 0);
        _loadPlaylist();
      }
    }
  }

  void _onRemoveAll() {
    for (Track track in _likedTracks){
      if (track.liked == 1) {
        widget.dbService.updateInteraction(track.trackId, 0);
      }
    }
    _loadPlaylist();
  }

  void _confirmAndResetLikedTracks(BuildContext context) {
    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppresion"),
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
              child: const Text("Supprimer Tout", style: TextStyle(color: Colors.red)),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Ma Playlist"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
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
              "Pas encore de recommandation",
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
      // mainAxisSize: MainAxisSize.min, // Non nécessaire dans une Column principale
      children: [
        // Bouton de suppression globale (laissé dans le Column, mais vous devriez considérer l'AppBar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmAndResetLikedTracks(context),
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text(
                  'Supprimer Toute la Liste',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),

        // 1. CORRECTION: Envelopper la ListView dans Expanded
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _likedTracks.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final track = _likedTracks[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(Icons.music_note, color: Colors.blueAccent),
                  ),
                  title: Text(
                    track.trackName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.trackArtist,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 2. CORRECTION: Remplacer le FloatingActionButton par un IconButton
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${track.trackPopularity.toInt()}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8), // Petit espace
                      IconButton( // Utilisation d'un IconButton plus approprié
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _onRemove(track.trackId),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ]
    );
  }
}