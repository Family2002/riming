import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

const _themeIdKey = 'riming_theme_id';
const _themeModeKey = 'riming_theme_mode';

class ThemeSettings {
  const ThemeSettings({
    this.themeId = AppThemeId.tealFocus,
    this.themeMode = ThemeMode.system,
  });

  final AppThemeId themeId;
  final ThemeMode themeMode;

  ThemeSettings copyWith({
    AppThemeId? themeId,
    ThemeMode? themeMode,
  }) {
    return ThemeSettings(
      themeId: themeId ?? this.themeId,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  ThemeSettingsNotifier(this._prefs) : super(const ThemeSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final idName = _prefs.getString(_themeIdKey);
    final modeName = _prefs.getString(_themeModeKey);
    final id = AppThemeId.values.firstWhere(
      (e) => e.name == idName,
      orElse: () => AppThemeId.tealFocus,
    );
    final mode = ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.system,
    );
    state = ThemeSettings(themeId: id, themeMode: mode);
  }

  Future<void> setThemeId(AppThemeId id) async {
    state = state.copyWith(themeId: id);
    await _prefs.setString(_themeIdKey, id.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeModeKey, mode.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier(ref.watch(sharedPreferencesProvider));
});
