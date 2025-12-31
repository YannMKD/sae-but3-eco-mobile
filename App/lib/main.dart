import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/playlist_screen.dart';
import 'package:flutter_application_1/screens/app_layouts.dart';
import '../services/database_service.dart';
import '../models/track.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  final dbService = await DatabaseService.init(dbFileName: 'app_data.db');

  runApp(MyApp(dbService: dbService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;

  const MyApp({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AppLayout(dbService: dbService), 
    );
  }
}