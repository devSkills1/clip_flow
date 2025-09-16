// Theme tokens: colors, typography, and shared tokens for theming.
// Keep only semantic, project-wide tokens here; no widget-specific values.
import 'package:flutter/material.dart';

class ThemeTokens {
  ThemeTokens._();

  // Seed color for ColorScheme generation (moved from hardcoded value).
  static const Color seedColor = Color(0xFF007AFF);

  // Font family used across the app; provide a reasonable fallback list.
  // Keep the actual font asset configuration in pubspec.yaml.
  static const String primaryFontFamily = 'SF Pro Display';
  static const List<String> fallbackFonts = <String>[
    'system-ui',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
}