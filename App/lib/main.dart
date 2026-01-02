import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/start_screen.dart';
import '../services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  final dbService = await DatabaseService.init(dbFileName: 'app_data.db');
  final prefs = await SharedPreferences.getInstance();

  print('preference : ${prefs}');
  final String savedMode = prefs.getString('theme_mode') ?? "dark";

  runApp(MyApp(dbService: dbService, initialMode: savedMode));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final String initialMode; 

  const MyApp({super.key, required this.dbService, required this.initialMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData(
        brightness: initialMode == "dark" ? Brightness.dark : Brightness.light,
      ),
      home: SplashScreen(dbService: dbService, mode: initialMode), 
    );
  }
}