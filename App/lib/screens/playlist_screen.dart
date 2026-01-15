import 'package:flutter/material.dart';
import 'package:trackstar/models/glass_box.dart';
import '../services/database_service.dart';
import '../models/track.dart';

enum SortType { title, artist, popularity }

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
    
    if (mounted) {
      setState(() {
        _likedTracks = tracks;
        _isLoading = false;
        _applyFilters();
      });
    }
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

  void _onRemove(String trackId) {
    setState(() {
      _likedTracks.removeWhere((track) => track.trackId == trackId);
      _applyFilters();
    });

    widget.dbService.updateInteraction(trackId, 0);
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
          title: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white),"Confirmer la suppression"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
          content: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white), "Êtes-vous sûr de vouloir supprimer toute votre like list ? Cette action est iréversible"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: Text(style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white), "Annuler")
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
    return Scaffold(
      backgroundColor: widget.mode == "light" ? const Color.fromARGB(255, 248, 247, 241) : Colors.black,
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nombre de titres : ${_filteredTracks.length}',
                      style: TextStyle(fontWeight: FontWeight.bold,  color: widget.mode == "light" ? Colors.black : Colors.white),
                      textAlign: TextAlign.left,
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmAndResetLikedTracks(context),
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text(
                        'Tout supprimer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.mode == "light" ? Colors.grey[200] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: widget.mode == "light" ? Colors.black : Colors.white),
                          decoration: InputDecoration(
                            hintText: "Artistes, morceaux...",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 5),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.sort, color: widget.mode == "light" ? Colors.black : Colors.white),
                      onPressed: _showFilterModal,
                    )
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _filteredTracks.length) return null;
              final track = _filteredTracks[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                child: GlassBox(
                  width: MediaQuery.of(context).size.width,
                  borderRadius: BorderRadius.circular(10),
                  padding: 1,
                  mode: widget.mode,
                  child: IntrinsicHeight(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                ),
              );
            },
            childCount: _filteredTracks.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}