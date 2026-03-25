import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'genui/registry/init_registry.dart';

import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitRegistry.initialize();
  LocalNotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('theme_mode');
  final themeMode = themeIndex != null
      ? ThemeMode.values[themeIndex]
      : ThemeMode.light;

  final session = await AuthService.getCachedSession();

  runApp(MyApp(initialSession: session, initialThemeMode: themeMode));
}
