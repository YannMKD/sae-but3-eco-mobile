import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: "Ma première app",
      home: Scaffold(
        backgroundColor: Colors.yellow.shade100,
        body: Center(
          child: Stack(
              children: <Widget>[
              Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromRGBO(188, 170, 164, 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 20.0
                    ),
                  ]
                  ),
                child: const Center(
                  child: Text(
                    'First song',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.yellow.shade100,
          items: const [
          BottomNavigationBarItem(
          icon: Icon(Icons.home), 
          label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music_rounded),
          label: "Playlist"),
        ]),
      ),
  )
  );
}
