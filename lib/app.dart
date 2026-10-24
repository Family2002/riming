import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'ui/core/theme/app_themes.dart';
import 'ui/core/theme/riming_glass_theme.dart';
import 'ui/core/theme/theme_preferences.dart';
import 'ui/features/history/views/history_screen.dart';
import 'ui/features/home/views/home_screen.dart';
import 'ui/features/settings/views/theme_settings_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: 'themes',
          builder: (context, state) => const ThemeSettingsScreen(),
        ),
      ],
    ),
  ],
);

class RimingApp extends ConsumerWidget {
  const RimingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);

    return LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 28,
        quality: GlassQuality.standard,
      ),
      child: MaterialApp.router(
        title: '日铭',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.light(settings.themeId),
        darkTheme: AppThemes.dark(settings.themeId),
        themeMode: settings.themeMode,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
        builder: (context, child) {
          final scheme = Theme.of(context).colorScheme;
          return GlassTheme(
            data: rimingGlassTheme(scheme),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
