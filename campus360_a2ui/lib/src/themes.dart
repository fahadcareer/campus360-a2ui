import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'res/colors/colors.dart';

class ThemeClass {
  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.chatGptLightBg,
      dividerColor: AppColors.chatGptLightBorder,

      // Sidebar/AppBar color equivalent
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.chatGptLightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.chatGptLightSecondaryText),
        titleTextStyle: TextStyle(
          color: AppColors.chatGptLightPrimaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodyLarge: const TextStyle(
          color: AppColors.chatGptLightPrimaryText,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.chatGptLightPrimaryText,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          color: AppColors.chatGptLightSecondaryText,
          fontSize: 12,
        ),
        titleLarge: const TextStyle(
          color: AppColors.chatGptLightPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: const TextStyle(
          color: AppColors.chatGptLightPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: AppColors.chatGptLightSecondaryText,
        size: 20,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.chatGptLightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.chatGptLightSecondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: AppColors.chatGptLightSurface,
        onSurface: AppColors.chatGptLightPrimaryText,
        primary: primaryColor,
        onPrimary: Colors.white,
        outline: AppColors.chatGptLightBorder,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),

      // Card/Surface
      cardTheme: CardThemeData(
        color: AppColors.chatGptLightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.chatGptLightBorder),
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.chatGptBg,
      dividerColor: AppColors.chatGptBorder,

      // Sidebar/AppBar color
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.chatGptBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.chatGptPrimaryText),
        titleTextStyle: TextStyle(
          color: AppColors.chatGptPrimaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodyLarge: const TextStyle(
          color: AppColors.chatGptPrimaryText,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.chatGptPrimaryText,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          color: AppColors.chatGptSecondaryText,
          fontSize: 12,
        ),
        titleLarge: const TextStyle(
          color: AppColors.chatGptPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: const TextStyle(
          color: AppColors.chatGptPrimaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: AppColors.chatGptPrimaryText,
        size: 20,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.chatGptSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.chatGptSecondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: AppColors.chatGptSurface,
        onSurface: AppColors.chatGptPrimaryText,
        primary: primaryColor,
        onPrimary: Colors.white,
        outline: AppColors.chatGptBorder,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),

      // Card/Surface
      cardTheme: CardThemeData(
        color: AppColors.chatGptSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.chatGptBorder),
        ),
      ),
    );
  }
}
