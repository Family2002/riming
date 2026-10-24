import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Builds liquid-glass theme defaults tinted by the active [ColorScheme].
GlassThemeData rimingGlassTheme(ColorScheme scheme) {
  final lightTint = scheme.primary.withValues(alpha: 0.14);
  final darkTint = scheme.primary.withValues(alpha: 0.18);

  return GlassThemeData(
    light: GlassThemeVariant(
      settings: GlassThemeSettings(
        blur: 12,
        thickness: 28,
        glassColor: lightTint,
      ),
      quality: GlassQuality.standard,
      glowColors: GlassGlowColors(
        primary: scheme.primary.withValues(alpha: 0.55),
        glowBlurRadius: 10,
        glowSpreadRadius: 0.15,
        glowOpacity: 0.65,
      ),
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings(
        blur: 14,
        thickness: 34,
        glassColor: darkTint,
      ),
      quality: GlassQuality.standard,
      glowColors: GlassGlowColors(
        primary: scheme.primary.withValues(alpha: 0.45),
        glowBlurRadius: 10,
        glowSpreadRadius: 0.15,
        glowOpacity: 0.55,
      ),
    ),
  );
}
