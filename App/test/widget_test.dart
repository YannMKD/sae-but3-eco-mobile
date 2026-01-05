import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final dbService = await DatabaseService.init(dbFileName: 'app_data.db');
    final prefs = await SharedPreferences.getInstance();

    final String savedMode = prefs.getString('theme_mode') ?? "dark";
    
    await tester.pumpWidget(MyApp(dbService: dbService, initialMode: savedMode,));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
