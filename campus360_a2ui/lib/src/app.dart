import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/chat_controller.dart';
import 'providers/theme_controller.dart';
import 'pages/chat_screen.dart';
import 'pages/login_screen.dart';
import 'res/dimentions/ui.dart';
import 'res/dimentions/app_dimensions.dart';
import 'res/dimentions/space.dart';
import 'res/style/app_typography.dart';
import 'res/colors/colors.dart';
import 'themes.dart';

class MyApp extends StatelessWidget {
  final Map<String, String>? initialSession;
  final ThemeMode initialThemeMode;

  const MyApp({super.key, this.initialSession, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(initialMode: initialThemeMode),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ChatController()),
      ],
      child: Campus360App(initialSession: initialSession),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Campus360App extends StatelessWidget {
  final Map<String, String>? initialSession;

  const Campus360App({super.key, this.initialSession});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    // If there's an initial session, initialize ChatProvider after build
    if (initialSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        if (!chatProvider.isInitialized) {
          chatProvider.initialize(
            initialSession!['userId']!,
            initialSession!['token']!,
          );
        }
      });
    }

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Campus360 Chatbot',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeClass.lightTheme(AppColors.primaryColor),
          darkTheme: ThemeClass.darkTheme(AppColors.primaryColor),
          builder: (context, child) {
            // Initialize responsive dimensions
            UI.init(context);
            AppDimensions.init(context);
            Space.init();
            TextStyles.init();

            final lightTheme = ThemeClass.lightTheme(AppColors.primaryColor);
            final darkTheme = ThemeClass.darkTheme(AppColors.primaryColor);

            return Theme(
              data: themeController.isDarkMode ? darkTheme : lightTheme,
              child: child!,
            );
          },
          home: initialSession != null
              ? const ChatScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
