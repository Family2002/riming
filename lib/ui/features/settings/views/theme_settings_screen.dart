import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_preferences.dart';
import '../../../core/widgets/riming_atmosphere.dart';
import '../../../core/widgets/riming_surface_card.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return GlassScaffold(
      background: const RimingAtmosphere(),
      backgroundColor: scheme.surface,
      extendBody: false,
      edgeFade: false,
      contentAwareBrightness: false,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        title: Text(
          '主题',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(CupertinoIcons.back, color: scheme.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            '让日铭更贴合你的节奏',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '外观',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ModeCard(
            title: '跟随系统',
            subtitle: '自动匹配浅色或深色',
            icon: CupertinoIcons.circle_lefthalf_fill,
            selected: settings.themeMode == ThemeMode.system,
            onTap: () => ref
                .read(themeSettingsProvider.notifier)
                .setThemeMode(ThemeMode.system),
          ),
          _ModeCard(
            title: '浅色',
            subtitle: '明亮、通透',
            icon: CupertinoIcons.sun_max,
            selected: settings.themeMode == ThemeMode.light,
            onTap: () => ref
                .read(themeSettingsProvider.notifier)
                .setThemeMode(ThemeMode.light),
          ),
          _ModeCard(
            title: '深色',
            subtitle: '夜间更柔和',
            icon: CupertinoIcons.moon_stars,
            selected: settings.themeMode == ThemeMode.dark,
            onTap: () => ref
                .read(themeSettingsProvider.notifier)
                .setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '配色',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...AppThemes.all.map((option) {
            final selected = option.id == settings.themeId;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RimingSurfaceCard(
                emphasized: selected,
                onTap: () => ref
                    .read(themeSettingsProvider.notifier)
                    .setThemeId(option.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _Swatch(color: option.seed),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option.nameZh,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (selected)
                      Icon(CupertinoIcons.checkmark_circle_fill,
                          color: scheme.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RimingSurfaceCard(
        emphasized: selected,
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: selected
              ? Icon(CupertinoIcons.checkmark_alt, color: scheme.primary)
              : null,
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '色块',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 3,
          ),
        ),
      ),
    );
  }
}
