import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackstar/screens/onboarding_screen.dart';
import 'package:trackstar/screens/start_screen.dart';
import 'package:trackstar/services/prefs_service.dart';
import '../services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final dbService = await DatabaseService.init(dbFileName: 'app_data.db');
  final prefs = await SharedPreferences.getInstance();

  print('preference : ${prefs.getString('theme_mode')}');
  if (prefs.getString('theme_mode') == null) {
    await prefs.setString('theme_mode', 'dark');
  }

  final String savedMode = prefs.getString('theme_mode') ?? "dark";

  // await PrefsService.resetAllData();

  final bool onboardingDone = await PrefsService.isOnboardingComplete();

  runApp(MyApp(dbService: dbService, initialMode: savedMode, startWithOnboarding: !onboardingDone));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final String initialMode; 

  final bool startWithOnboarding;

  const MyApp({super.key, required this.dbService, required this.initialMode, required this.startWithOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trackstar',
      theme: ThemeData(
        brightness: initialMode == "dark" ? Brightness.dark : Brightness.light,
      ),
      home:
        SplashScreen(dbService: dbService, mode: initialMode, startWithOnboarding: startWithOnboarding), 
    );
  }
}