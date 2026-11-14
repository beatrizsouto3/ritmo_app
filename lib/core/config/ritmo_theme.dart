import 'package:flutter/material.dart';

ThemeData buildRitmoTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0A4174))
      .copyWith(
        primary: const Color(0xFF0A4174),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFD3E3FF),
        onPrimaryContainer: const Color(0xFF002B52),
        secondary: const Color(0xFF33628A),
        secondaryContainer: const Color(0xFFA4D0FE),
        surface: const Color(0xFFF8F9FF),
        onSurface: const Color(0xFF001C38),
        outline: const Color(0xFF737780),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFF4FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
