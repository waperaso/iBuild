import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'color_schemes/ibuild_scheme.dart';
import 'color_schemes/amethyst_scheme.dart';
import 'color_schemes/aurora_scheme.dart';
import 'color_schemes/crimson_scheme.dart';
import 'color_schemes/emerald_scheme.dart';
import 'color_schemes/graphite_scheme.dart';
import 'color_schemes/lime_scheme.dart';
import 'color_schemes/meridian_scheme.dart';
import 'color_schemes/midnight_scheme.dart';
import 'color_schemes/mint_scheme.dart';
import 'color_schemes/ocean_scheme.dart';
import 'color_schemes/plum_scheme.dart';
import 'color_schemes/rose_scheme.dart';
import 'color_schemes/sand_scheme.dart';
import 'color_schemes/sapphire_scheme.dart';
import 'color_schemes/sunset_scheme.dart';

/// Runtime palette ids. Register light/dark [AppColors] pairs under
/// `color_schemes/`; first entry ([ibuild]) is the default brand palette.
enum AppPalette {
  ibuild('iBuild', ibuildScheme, ibuildSchemeDark),
  meridian('Meridian', meridianScheme, meridianSchemeDark),
  aurora('Aurora', auroraScheme, auroraSchemeDark),
  lime('Lime', limeScheme, limeSchemeDark),
  sapphire('Sapphire', sapphireScheme, sapphireSchemeDark),
  emerald('Emerald', emeraldScheme, emeraldSchemeDark),
  sunset('Sunset', sunsetScheme, sunsetSchemeDark),
  rose('Rose', roseScheme, roseSchemeDark),
  graphite('Graphite', graphiteScheme, graphiteSchemeDark),
  plum('Plum', plumScheme, plumSchemeDark),
  ocean('Ocean', oceanScheme, oceanSchemeDark),
  sand('Sand', sandScheme, sandSchemeDark),
  crimson('Crimson', crimsonScheme, crimsonSchemeDark),
  midnight('Midnight', midnightScheme, midnightSchemeDark),
  mint('Mint', mintScheme, mintSchemeDark),
  amethyst('Amethyst', amethystScheme, amethystSchemeDark);

  const AppPalette(this.label, this.light, this.dark);

  final String label;
  final AppColors light;
  final AppColors dark;
}

/// Current palette + brightness selection. UI reads this to build the theme,
/// and the Profile screen mutates it to switch schemes live.
class ThemeState {
  const ThemeState({
    this.palette = AppPalette.ibuild,
    this.themeMode = ThemeMode.light,
  });

  final AppPalette palette;
  final ThemeMode themeMode;

  AppColors get light => palette.light;
  AppColors get dark => palette.dark;

  ThemeState copyWith({AppPalette? palette, ThemeMode? themeMode}) =>
      ThemeState(
        palette: palette ?? this.palette,
        themeMode: themeMode ?? this.themeMode,
      );
}

/// Persists palette + theme mode; restores from [SharedPreferences] after build.
class ThemeController extends Notifier<ThemeState> {
  static const _paletteKey = 'ibuild.theme.palette';
  static const _modeKey = 'ibuild.theme.mode';

  @override
  ThemeState build() {
    _restore();
    return const ThemeState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_paletteKey);
    final modeName = prefs.getString(_modeKey);
    var next = state;
    if (paletteName != null) {
      final resolved = paletteName == 'meridian' ? 'ibuild' : paletteName;
      for (final p in AppPalette.values) {
        if (p.name == resolved) {
          next = next.copyWith(palette: p);
          break;
        }
      }
      if (paletteName == 'meridian') {
        await prefs.setString(_paletteKey, AppPalette.ibuild.name);
      }
    }
    if (modeName != null) {
      for (final m in ThemeMode.values) {
        if (m.name == modeName) {
          next = next.copyWith(themeMode: m);
          break;
        }
      }
    }
    // Only publish (and rebuild the theme) if something was actually restored.
    if (!identical(next, state)) state = next;
  }

  void setPalette(AppPalette palette) {
    state = state.copyWith(palette: palette);
    _persist();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void toggleBrightness() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark,
    );
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, state.palette.name);
    await prefs.setString(_modeKey, state.themeMode.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
