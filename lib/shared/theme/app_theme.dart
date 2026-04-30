import 'package:flutter/material.dart';

class AppTheme {
  // Kolory z GDD v0.2
  static const Color slime = Color(0xFF7ec850);
  static const Color slimeDark = Color(0xFF4a8a2a);
  static const Color slimeGlow = Color(0xFFa8ff5a);
  static const Color bg = Color(0xFF0d0f0a);
  static const Color bg2 = Color(0xFF131710);
  static const Color bg3 = Color(0xFF1a1f13);
  static const Color card = Color(0xFF161c10);
  static const Color border = Color(0xFF2d3d1e);
  static const Color text = Color(0xFFcdd9b5);
  static const Color textDim = Color(0xFF7a8a62);
  static const Color accent = Color(0xFFff6b35);
  static const Color virus = Color(0xFFcc3333);
  static const Color dna = Color(0xFF5ab4ff);
  static const Color premium = Color(0xFFf0d060);
  static const Color goblin = Color(0xFFb8860b);

  static final ThemeData light = ThemeData.light().copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: card,
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      elevation: 0,
    ),
  );

  // Ciemny motyw (domyślny)
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      cardColor: card,
      canvasColor: bg2,
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(color: text, fontFamily: 'Creepster'),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textDim),
      ),
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: slime,
        onPrimary: bg,
        surface: bg,
        onSurface: text,
      ).copyWith(
        brightness: Brightness.dark,
        primary: slime,
        onPrimary: bg,
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: card,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      );

  static BoxDecoration get cardDecorationRounded => BoxDecoration(
        color: card,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      );
}


