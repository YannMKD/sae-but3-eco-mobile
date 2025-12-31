import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/glass_box.dart';
import '../services/database_service.dart';
import '../models/track.dart';

class PlaylistScreen extends StatefulWidget {
  final DatabaseService dbService;
  
  const PlaylistScreen({super.key, required this.dbService});

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
      backgroundColor: const Color.fromARGB(255, 248, 247, 241),
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

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _likedTracks.length,
            separatorBuilder: (context, index) => const Divider(thickness: 0,),
            itemBuilder: (context, index) {
              final track = _likedTracks[index];

              return GlassBox(
                width: MediaQuery.of(context).size.width,
                height: 94,
                borderRadius: BorderRadius.circular(5),
                child: ListTile(
                  leading: Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, size: 40, color: Colors.grey),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_outlined, color: Colors.black),
                        onPressed: () => _onRemove(track.trackId),
                      ),
                    ],
                  ),
                ),
              );
            }
          )
        )
      ]
    );
  }
}
