import 'package:flutter/material.dart';
import 'package:trackstar/models/glass_box.dart';
import 'package:trackstar/screens/loading.dart';
import '../services/database_service.dart';
import '../models/track.dart';

enum SortType { title, artist, popularity }

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
  List<Track> _filteredTracks = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  SortType _currentSortType = SortType.title;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    loadPlaylist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadPlaylist() async {    
    final tracks = await widget.dbService.getLikedTracks();
    
    setState(() {
      _likedTracks = tracks;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Track> temp = List.from(_likedTracks);

    if (_searchQuery.isNotEmpty) {
      temp = temp.where((t) => 
        t.trackName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        t.trackArtist.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    switch (_currentSortType) {
      case SortType.title:
        temp.sort((a, b) => _isAscending 
          ? a.trackName.toLowerCase().compareTo(b.trackName.toLowerCase())
          : b.trackName.toLowerCase().compareTo(a.trackName.toLowerCase()));
        break;
        
      case SortType.artist:
        temp.sort((a, b) => _isAscending 
          ? a.trackArtist.toLowerCase().compareTo(b.trackArtist.toLowerCase())
          : b.trackArtist.toLowerCase().compareTo(a.trackArtist.toLowerCase()));
        break;
        
      case SortType.popularity:
        temp.sort((a, b) => b.trackPopularity.compareTo(a.trackPopularity)); 
        break;
    }

    setState(() {
      _filteredTracks = temp;
    });
  }

  void _onRemove(String trackId) async {
   setState(() {
      _likedTracks.removeWhere((track) => track.trackId == trackId);
      _applyFilters();
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

  void _showFilterModal() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 130, 
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    return Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: widget.mode == "light" ? Colors.white : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAppleMusicOption("Titre", SortType.title, setModalState),
                          Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3), indent: 16, endIndent: 16),
                          _buildAppleMusicOption("Popularité", SortType.popularity, setModalState),
                          Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3), indent: 16, endIndent: 16),
                          _buildAppleMusicOption("Artiste", SortType.artist, setModalState),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppleMusicOption(String title, SortType type, StateSetter setModalState) {
    final bool isSelected = _currentSortType == type;
    final Color textColor = widget.mode == "light" ? Colors.black : Colors.white;

    String? subtitle;
    
    if (isSelected && type != SortType.popularity) {
      subtitle = _isAscending ? "A-Z" : "Z-A";
    }

    return InkWell(
      onTap: () {
        setModalState(() {
          if (_currentSortType == type) {
            if (type != SortType.popularity) {
              _isAscending = !_isAscending;
            }
          } else {
            _currentSortType = type;
            _isAscending = true; 
          }
        });
        setState(() {
          _applyFilters();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double wRatio = MediaQuery.of(context).size.width / 392.7;

    return Scaffold(
      backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading 
              ? Center(child: Loading(color: widget.mode == "light" ? Colors.black : Colors.white, size: 60 * wRatio))
              : (_likedTracks.isEmpty 
                  ? _buildEmptyState(wRatio) 
                  : _buildCustomScrollView(wRatio)),
          ),
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

  Widget _buildCustomScrollView(double wRatio) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0 * wRatio, vertical: 10.0 * wRatio),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nombre de titres : ${_filteredTracks.length}',
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
                        'Tout supprimer',
                        style: TextStyle(color: Colors.red, fontSize: 13 * wRatio),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45 * wRatio, 
                        decoration: BoxDecoration(
                          color: widget.mode == "light" ? Colors.grey[200] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(10 * wRatio),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white, fontSize: 14 * wRatio),
                          decoration: InputDecoration(
                            hintText: "Artistes, morceaux...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20 * wRatio),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10 * wRatio),
                          ),
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * wRatio),
                    IconButton(
                      icon: Icon(Icons.sort, color: widget.mode == "light" ? Colors.black : Colors.white, size: 24 * wRatio),
                      onPressed: _showFilterModal,
                    )
                  ],
                ),
                SizedBox(height: 10 * wRatio),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = _filteredTracks[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * wRatio, vertical: 6 * wRatio),
                child: _buildTrackItem(track, wRatio),
              );
            },
            childCount: _filteredTracks.length,
          ),
        ),
        
        SliverToBoxAdapter(child: SizedBox(height: 100 * wRatio)),
      ],
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