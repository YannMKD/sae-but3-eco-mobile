import 'package:flutter/material.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Playlist'),
        backgroundColor: Colors.yellow.shade200,
      ),
      body: const Center(
        child: Text(
          'Contenu de la Playlist (à implémenter)',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}