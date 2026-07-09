import 'package:flutter/material.dart';

class CozyTheme {
  // Base palette constants (used as defaults / fallbacks)
  static const Color oatmeal = Color(0xFFF5EFE6);
  static const Color oatmealDark = Color(0xFFEAE3D2);
  static const Color terracotta = Color(0xFFD95D39);
  static const Color terracottaDark = Color(0xFFC14F2E);
  static const Color mossGreen = Color(0xFF8FBC8F);
  static const Color forestGreen = Color(0xFF5F8575);
  static const Color charcoal = Color(0xFF2C3639);
  static const Color warmCream = Color(0xFFFFFDF9);

  // Border Radii
  static const double radiusLargeVal = 24.0;
  static const double radiusMediumVal = 16.0;
  static const double radiusSmallVal = 12.0;

  static BorderRadius get radiusLarge => BorderRadius.circular(radiusLargeVal);
  static BorderRadius get radiusMedium => BorderRadius.circular(radiusMediumVal);
  static BorderRadius get radiusSmall => BorderRadius.circular(radiusSmallVal);

  /// Build a full ThemeData from a [ThemePalette].
  static ThemeData buildTheme(ThemePalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final onPrimary = isDark ? Colors.white : palette.surfaceColor;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      primaryColor: palette.primaryColor,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primaryColor,
        onPrimary: onPrimary,
        secondary: palette.secondaryColor,
        onSecondary: palette.textColor,
        surface: palette.surfaceColor,
        onSurface: palette.textColor,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        outline: palette.borderColor,
      ),
      scaffoldBackgroundColor: palette.backgroundColor,
      cardTheme: CardThemeData(
        color: palette.surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLarge,
          side: BorderSide(color: palette.borderColor, width: 1.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.backgroundColor,
        foregroundColor: palette.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primaryColor,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textColor,
          side: BorderSide(color: palette.borderColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: palette.primaryColor,
        labelColor: palette.primaryColor,
        unselectedLabelColor: palette.textColor.withOpacity(0.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textColor,
        contentTextStyle: TextStyle(color: palette.surfaceColor),
      ),
      fontFamily: 'Outfit',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.textColor, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: palette.textColor, letterSpacing: -0.2),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: palette.textColor),
        bodyLarge: TextStyle(fontSize: 16, color: palette.textColor, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: palette.textColor),
      ),
    );
  }

  /// Convenience: the default light theme.
  static ThemeData get lightTheme => buildTheme(ThemePalette.defaultPalette);
}

// ---------------------------------------------------------------------------
// ThemePalette — centralised palette definition used by the whole app.
// ---------------------------------------------------------------------------

class ThemePalette {
  final String name;
  final Brightness brightness;
  final Color backgroundColor;   // scaffold background
  final Color surfaceColor;      // cards, sheets
  final Color primaryColor;      // filled buttons, active indicators
  final Color secondaryColor;    // secondary accents
  final Color textColor;         // body text
  final Color borderColor;       // card / button outlines
  final List<Color> previewColors; // 3-dot swatch for thumbnails

  const ThemePalette({
    required this.name,
    required this.brightness,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.borderColor,
    required this.previewColors,
  });

  // ---- Default (free — The Sunrise Studio) ----

  static const defaultPalette = ThemePalette(
    name: 'The Sunrise Studio',
    brightness: Brightness.light,
    backgroundColor: Color(0xFFFFF5E1), // Warm Cream
    surfaceColor: Color(0xFFFFFBF2),
    primaryColor: Color(0xFFD4A373),    // Golden Sand
    secondaryColor: Color(0xFFA3B18A),  // Mossy Green
    textColor: Color(0xFF3C3633),       // Dark Warm Grey
    borderColor: Color(0xFFE8D9C0),
    previewColors: [Color(0xFFFFF5E1), Color(0xFFD4A373), Color(0xFFA3B18A)],
  );

  // ---- Registry of unlockable themes (12 curated palettes) ----

  static final Map<String, ThemePalette> registry = {
    // 1. The Deep Work Zone
    'The Deep Work Zone': const ThemePalette(
      name: 'The Deep Work Zone',
      brightness: Brightness.dark,
      backgroundColor: Color(0xFF1A1C1E), // Deep Charcoal
      surfaceColor: Color(0xFF22262A),
      primaryColor: Color(0xFFE27D60),    // Muted Coral/Rust
      secondaryColor: Color(0xFF41B3A3),  // Teal Mist
      textColor: Color(0xFFF9F6F0),       // High Contrast
      borderColor: Color(0xFF2E3236),
      previewColors: [Color(0xFF1A1C1E), Color(0xFFE27D60), Color(0xFF41B3A3)],
    ),
    // 2. The Sunrise Studio (also the default, accessible as a named entry)
    'The Sunrise Studio': const ThemePalette(
      name: 'The Sunrise Studio',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFFF5E1),
      surfaceColor: Color(0xFFFFFBF2),
      primaryColor: Color(0xFFD4A373),
      secondaryColor: Color(0xFFA3B18A),
      textColor: Color(0xFF3C3633),
      borderColor: Color(0xFFE8D9C0),
      previewColors: [Color(0xFFFFF5E1), Color(0xFFD4A373), Color(0xFFA3B18A)],
    ),
    // 3. The Rainy Window
    'The Rainy Window': const ThemePalette(
      name: 'The Rainy Window',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFE3E9F2), // Mist Blue
      surfaceColor: Color(0xFFEDF1F8),
      primaryColor: Color(0xFF5D6D7E),    // Steel Blue
      secondaryColor: Color(0xFFAAB7B8),  // Dusty Blue
      textColor: Color(0xFF2C3E50),       // Deep Navy
      borderColor: Color(0xFFC8D3DF),
      previewColors: [Color(0xFFE3E9F2), Color(0xFF5D6D7E), Color(0xFFAAB7B8)],
    ),
    // 4. The Botanical Library
    'The Botanical Library': const ThemePalette(
      name: 'The Botanical Library',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFF0F2EF), // Off-White Grey
      surfaceColor: Color(0xFFF7F8F6),
      primaryColor: Color(0xFF2D6A4F),    // Deep Emerald
      secondaryColor: Color(0xFF7B4A31),  // Rich Brown
      textColor: Color(0xFF1B4332),       // Darkest Green
      borderColor: Color(0xFFCDD4CC),
      previewColors: [Color(0xFFF0F2EF), Color(0xFF2D6A4F), Color(0xFF7B4A31)],
    ),
    // 5. The Golden Hour
    'The Golden Hour': const ThemePalette(
      name: 'The Golden Hour',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFDF2E9), // Soft Apricot
      surfaceColor: Color(0xFFFEF7F0),
      primaryColor: Color(0xFFE67E22),    // Burnt Orange
      secondaryColor: Color(0xFFD35400),  // Pumpkin Spice
      textColor: Color(0xFF5D4037),       // Espresso
      borderColor: Color(0xFFEAD2BD),
      previewColors: [Color(0xFFFDF2E9), Color(0xFFE67E22), Color(0xFFD35400)],
    ),
    // 6. The Moonlight Garden
    'The Moonlight Garden': const ThemePalette(
      name: 'The Moonlight Garden',
      brightness: Brightness.dark,
      backgroundColor: Color(0xFF2C3E50), // Midnight Blue
      surfaceColor: Color(0xFF34495E),
      primaryColor: Color(0xFFBDC3C7),    // Silver Mist
      secondaryColor: Color(0xFF95A5A6),  // Cool Slate
      textColor: Color(0xFFECF0F1),       // Arctic White
      borderColor: Color(0xFF3D5166),
      previewColors: [Color(0xFF2C3E50), Color(0xFFBDC3C7), Color(0xFF95A5A6)],
    ),
    // 7. The Matcha Morning
    'The Matcha Morning': const ThemePalette(
      name: 'The Matcha Morning',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFF1F8E9), // Pale Lime
      surfaceColor: Color(0xFFF7FBF2),
      primaryColor: Color(0xFF8BC34A),    // Matcha Green
      secondaryColor: Color(0xFFAED581),  // Clover
      textColor: Color(0xFF33691E),       // Dark Forest
      borderColor: Color(0xFFD4EAB8),
      previewColors: [Color(0xFFF1F8E9), Color(0xFF8BC34A), Color(0xFFAED581)],
    ),
    // 8. The Dusty Vinyl
    'The Dusty Vinyl': const ThemePalette(
      name: 'The Dusty Vinyl',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFD7CCC8), // Warm Sandstone
      surfaceColor: Color(0xFFE0D5D0),
      primaryColor: Color(0xFF8D6E63),    // Terracotta
      secondaryColor: Color(0xFFBCAAA4),  // Rose Taupe
      textColor: Color(0xFF3E2723),       // Dark Cocoa
      borderColor: Color(0xFFC0AEAA),
      previewColors: [Color(0xFFD7CCC8), Color(0xFF8D6E63), Color(0xFFBCAAA4)],
    ),
    // 9. The Lavender Fog
    'The Lavender Fog': const ThemePalette(
      name: 'The Lavender Fog',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFF3E5F5), // Lilac Whisper
      surfaceColor: Color(0xFFF9F0FB),
      primaryColor: Color(0xFF9575CD),    // Soft Purple
      secondaryColor: Color(0xFFB39DDB),  // Muted Violet
      textColor: Color(0xFF4527A0),       // Deep Indigo
      borderColor: Color(0xFFDCC8E8),
      previewColors: [Color(0xFFF3E5F5), Color(0xFF9575CD), Color(0xFFB39DDB)],
    ),
    // 10. The Library Archive
    'The Library Archive': const ThemePalette(
      name: 'The Library Archive',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFF5F5DC), // Beige Parchment
      surfaceColor: Color(0xFFFAFAEA),
      primaryColor: Color(0xFF8B4513),    // Saddle Brown
      secondaryColor: Color(0xFFA0522D),  // Sienna
      textColor: Color(0xFF2B1B17),       // Iron Black
      borderColor: Color(0xFFDDDDC0),
      previewColors: [Color(0xFFF5F5DC), Color(0xFF8B4513), Color(0xFFA0522D)],
    ),
    // 11. The Arctic Cabin
    'The Arctic Cabin': const ThemePalette(
      name: 'The Arctic Cabin',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFFFFFF), // Pure White
      surfaceColor: Color(0xFFF8FAFB),
      primaryColor: Color(0xFF3498DB),    // Electric Blue
      secondaryColor: Color(0xFF85C1E9),  // Sky Blue
      textColor: Color(0xFF212121),       // Jet Black
      borderColor: Color(0xFFDDE8F0),
      previewColors: [Color(0xFFFFFFFF), Color(0xFF3498DB), Color(0xFF85C1E9)],
    ),
    // 12. The Desert Oasis
    'The Desert Oasis': const ThemePalette(
      name: 'The Desert Oasis',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFFF3E0), // Champagne
      surfaceColor: Color(0xFFFFF8F0),
      primaryColor: Color(0xFFBF360C),    // Rust
      secondaryColor: Color(0xFFFF7043),  // Coral Clay
      textColor: Color(0xFF4E342E),       // Mud
      borderColor: Color(0xFFEDD8C0),
      previewColors: [Color(0xFFFFF3E0), Color(0xFFBF360C), Color(0xFFFF7043)],
    ),
    // 13. The Neon Tokyo (Premium)
    'The Neon Tokyo': const ThemePalette(
      name: 'The Neon Tokyo',
      brightness: Brightness.dark,
      backgroundColor: Color(0xFF0D0D0D), // Deep Void
      surfaceColor: Color(0xFF1A1A2E),    // Dark Indigo
      primaryColor: Color(0xFFFF2D78),    // Hot Pink Neon
      secondaryColor: Color(0xFF00F5FF),  // Cyan Neon
      textColor: Color(0xFFE8E8E8),       // Off White
      borderColor: Color(0xFF2A2A40),
      previewColors: [Color(0xFF0D0D0D), Color(0xFFFF2D78), Color(0xFF00F5FF)],
    ),
    // 14. The Rose Quartz (Premium)
    'The Rose Quartz': const ThemePalette(
      name: 'The Rose Quartz',
      brightness: Brightness.light,
      backgroundColor: Color(0xFFFFF0F3), // Blush White
      surfaceColor: Color(0xFFFFF8FA),
      primaryColor: Color(0xFFD63384),    // Deep Rose
      secondaryColor: Color(0xFFF48FB1),  // Ballet Pink
      textColor: Color(0xFF4A0E2B),       // Dark Plum
      borderColor: Color(0xFFF7C5D5),
      previewColors: [Color(0xFFFFF0F3), Color(0xFFD63384), Color(0xFFF48FB1)],
    ),
    // 15. The Midnight Ink (Premium — Top Tier)
    'The Midnight Ink': const ThemePalette(
      name: 'The Midnight Ink',
      brightness: Brightness.dark,
      backgroundColor: Color(0xFF080C14), // Ink Black
      surfaceColor: Color(0xFF111827),    // Dark Slate
      primaryColor: Color(0xFF6C63FF),    // Electric Violet
      secondaryColor: Color(0xFF4ECDC4),  // Turquoise Glow
      textColor: Color(0xFFF1F5F9),       // Ghost White
      borderColor: Color(0xFF1E2A3A),
      previewColors: [Color(0xFF080C14), Color(0xFF6C63FF), Color(0xFF4ECDC4)],
    ),
  };

  static ThemePalette get(String name) {
    return registry[name] ?? defaultPalette;
  }
}
