import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Hero primary action — premium liquid glass circle (no glow overlays).
class PrimaryRecordButton extends StatelessWidget {
  const PrimaryRecordButton({
    super.key,
    required this.hasOngoing,
    required this.onPressed,
    this.size = 156,
  });

  final bool hasOngoing;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = hasOngoing ? '切换事项' : '开始记录';
    final icon =
        hasOngoing ? CupertinoIcons.arrow_2_squarepath : CupertinoIcons.play_fill;

    // Official iOS 27 material + light ColorScheme tint (not a solid blob).
    final base = isDark
        ? LiquidGlassSettings.ios27Dark
        : LiquidGlassSettings.ios27Light;
    final settings = base.copyWith(
      glassColor: Color.alphaBlend(
        scheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
        base.glassColor,
      ),
      glowIntensity: 0,
    );

    // Lock adaptive ceiling so wrap(adaptiveQuality: true) cannot downgrade
    // this static hero CTA away from Impeller premium / iOS 27 material.
    return Semantics(
      button: true,
      label: label,
      child: GlassAdaptiveScope(
        minQuality: GlassQuality.premium,
        maxQuality: GlassQuality.premium,
        child: SizedBox(
          width: size,
          height: size,
          child: GlassButton.custom(
            onTap: onPressed,
            width: size,
            height: size,
            useOwnLayer: true,
            quality: GlassQuality.premium,
            shape: const LiquidOval(),
            stretch: 0.15,
            interactionScale: 1.05,
            glowRadius: 0,
            glowOpacity: 0,
            settings: settings,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: size * 0.26, color: scheme.onSurface),
                SizedBox(height: size * 0.04),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
