import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_themes.dart';
import '../theme/theme_preferences.dart';

/// Theme wallpaper backdrop for [GlassScaffold] refraction.
///
/// Picks a bundled JPG from [themeSettingsProvider] + resolved [Brightness],
/// so it updates when the user changes palette or light/dark mode.
class RimingAtmosphere extends ConsumerWidget {
  const RimingAtmosphere({super.key});

  /// Asset path for [id] at [brightness] (resolved light/dark, not ThemeMode).
  static String assetFor(AppThemeId id, Brightness brightness) {
    final stem = switch (id) {
      AppThemeId.tealFocus => 'teal',
      AppThemeId.wellnessPurple => 'purple',
      AppThemeId.softEarth => 'earth',
      AppThemeId.oceanBlue => 'ocean',
      AppThemeId.charcoalMinimal => 'charcoal',
      AppThemeId.warmSand => 'sand',
    };
    final mode = brightness == Brightness.dark ? 'dark' : 'light';
    return 'assets/backgrounds/${stem}_$mode.jpg';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeSettingsProvider.select((s) => s.themeId));
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final asset = assetFor(themeId, brightness);
    final dark = brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          key: ValueKey(asset),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
        // Very light ColorScheme wash so glass/UI stay cohesive with the seed.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primary.withValues(alpha: dark ? 0.10 : 0.06),
                scheme.surface.withValues(alpha: dark ? 0.14 : 0.08),
                scheme.tertiary.withValues(alpha: dark ? 0.08 : 0.05),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
