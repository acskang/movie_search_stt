import 'package:flutter/material.dart';
import 'screens/movie_phrase_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MoviePhraseApp());
}

class MoviePhraseApp extends StatelessWidget {
  const MoviePhraseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppConstants.primaryColor,
              secondary: AppConstants.secondaryColor,
              surface: Color(AppConstants.cardColorValue),
            ),
        cardTheme: CardThemeData(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppConstants.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppConstants.primaryColor,
              secondary: AppConstants.secondaryColor,
              surface: Color(AppConstants.cardColorValue),
            ),
        cardTheme: CardThemeData(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const MoviePhraseScreen(),
    );
  }
}
