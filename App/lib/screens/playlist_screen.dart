import 'package:flutter/material.dart';
import 'package:trackstar/models/glass_box.dart';
import 'package:trackstar/screens/loading.dart';
import '../services/database_service.dart';
import '../models/track.dart';

class PlaylistScreen extends StatefulWidget {
  final DatabaseService dbService;
  final String mode;
  final VoidCallback onNotifyUpdate;

  const PlaylistScreen({super.key, required this.dbService, required this.mode, required this.onNotifyUpdate,});

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

  void _onRemove(String trackId) async {
   setState(() {
      _likedTracks.removeWhere((track) => track.trackId == trackId);
    });

    await widget.dbService.updateInteraction(trackId, 0);
    
    widget.onNotifyUpdate(); 
    
    loadPlaylist();
  }

  void _onRemoveAll() async {
    setState(() => _isLoading = true);

    for (Track track in _likedTracks) {
      if (track.liked == 1) {
        await widget.dbService.updateInteraction(track.trackId, 0);
      }
    }
    
    widget.onNotifyUpdate(); 
    
    loadPlaylist();
  }

  void _confirmAndResetLikedTracks(BuildContext context) {
    final double wRatio = MediaQuery.of(context).size.width / 392.7;

    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Tu confirmes ?",
            style: TextStyle(
              color: widget.mode == "light" ? Colors.black : Colors.white, 
              fontSize: 18 * wRatio 
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30 * wRatio) 
          ),
          backgroundColor: widget.mode == "light" 
              ? const Color.fromARGB(249, 248, 247, 248) 
              : const Color.fromARGB(249, 12, 12, 12),
          content: Text(
            "Tu supprimeras toutes les sources de ta bibliothèque ? Cette action est irréversible",
            style: TextStyle(
              color: widget.mode == "light" ? Colors.black45 : Colors.white54,
              fontSize: 14 * wRatio 
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20 * wRatio, vertical: 10 * wRatio),
                side: BorderSide(color: widget.mode == "light" ? Colors.black38 : Colors.white24),
              ),
              onPressed: () => Navigator.of(context).pop(), 
              child: Text(
                "Annuler",
                style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white),
              )
            ), 
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20 * wRatio, vertical: 10 * wRatio),
                backgroundColor: widget.mode == "light" ? Colors.black : Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _onRemoveAll();
              },
              child: Text(
                "Supprimer tout",
                style: TextStyle(color: widget.mode == "light" ? Colors.white : Colors.black),
              ),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final double wRatio = MediaQuery.of(context).size.width / 392.7;

    return Scaffold(
      backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: Stack(
        children: [
          SafeArea(child: _buildBody(wRatio)),
          _buildOverlayGradientBottom(),
        ]
      ),
    );
  }

  Widget _buildOverlayGradientBottom() {
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
              stops: const [0.0, 0.3, 0.97, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayGradientTop() {
    return IgnorePointer(
      child: Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241) : Colors.black,
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
                widget.mode == "light" ?const Color.fromARGB(255, 248, 247, 241).withValues(alpha: 0) : Colors.black.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.03, 0.85, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double wRatio) {
    if (_isLoading) {
      return Center(child: Loading(color: widget.mode == "light" ? Colors.black : Colors.white, size: 60 * wRatio));
    }

    if (_likedTracks.isEmpty) {
      return _buildEmptyState(wRatio);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0 * wRatio, vertical: 10 * wRatio),
          child: Column(
            children: [
              Text(
                'Nombre de titres : ${_likedTracks.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,  
                  fontSize: 14 * wRatio,
                  color: widget.mode == "light" ? Colors.black : Colors.white
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmAndResetLikedTracks(context),
                icon: Icon(Icons.delete_sweep, color: Colors.red, size: 20 * wRatio),
                label: Text(
                  'Supprimer Toute la Liste',
                  style: TextStyle(color: Colors.red, fontSize: 13 * wRatio),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              ListView.separated(
                padding: EdgeInsets.fromLTRB(16 * wRatio, 16 * wRatio, 16 * wRatio, 16 * wRatio), 
                itemCount: _likedTracks.length,
                separatorBuilder: (context, index) => SizedBox(height: 10 * wRatio),
                itemBuilder: (context, index) {
                  final track = _likedTracks[index];
                  return _buildTrackItem(track, wRatio);
                },
              ),
              _buildOverlayGradientTop(),
            ]
          ),
        )
      ]
    );
  }

  Widget _buildTrackItem(Track track, double wRatio) {
    return GlassBox(
      width: double.infinity,
      borderRadius: BorderRadius.circular(10 * wRatio),
      padding: 1,
      mode: widget.mode,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12 * wRatio, vertical: 4 * wRatio),
        leading: Container(
          height: 60 * wRatio, 
          width: 60 * wRatio,
          decoration: BoxDecoration(
            color: widget.mode == "light" ? Colors.grey[300] : Colors.white10,
            borderRadius: BorderRadius.circular(8 * wRatio),
          ),
          child: Icon(Icons.music_note, size: 30 * wRatio, color: Colors.grey),
        ),
        title: Text(
          track.trackName,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16 * wRatio,
            color: widget.mode == "light" ? Colors.black : Colors.white
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.trackArtist,
          style: TextStyle(
            fontSize: 14 * wRatio,
            color: widget.mode == "light" ? Colors.grey[700] : Colors.white70
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_outlined, 
            size: 24 * wRatio,
            color: widget.mode == "light" ? Colors.black : Colors.white
          ),
          onPressed: () => _onRemove(track.trackId),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double wRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off_rounded, 
            size: 64 * wRatio,
            color: Colors.grey[400]
          ),
          SizedBox(height: 16 * wRatio),
          Text(
            "Pas encore de sources ajoutées",
            style: TextStyle(
              fontSize: 18 * wRatio,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500
            ),
          ),
          SizedBox(height: 8 * wRatio),
          Text(
            "Retournez dans la galaxie pour ajouter des sources !",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14 * wRatio 
            ),
          ),
        ],
      ),
    );
  }
}