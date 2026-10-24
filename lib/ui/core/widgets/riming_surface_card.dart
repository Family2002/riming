import 'package:flutter/material.dart';

/// Opaque, readable content card — for timeline rows and dense lists.
///
/// Liquid glass is reserved for chrome (bars, primary CTA, sheets). Content
/// stays solid so text contrast and hit targets stay reliable.
class RimingSurfaceCard extends StatelessWidget {
  const RimingSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.emphasized = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasized
        ? scheme.primaryContainer.withValues(alpha: 0.85)
        : scheme.surfaceContainerLow.withValues(alpha: 0.95);

    return Material(
      color: color,
      elevation: emphasized ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: scheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
