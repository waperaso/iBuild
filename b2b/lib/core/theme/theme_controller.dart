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

/// Runtime palette ids. Register light/dark [AppColors] under `color_schemes/`;
/// first entry ([ibuild]) is the default brand palette.
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

/// Active palette + [ThemeMode].
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

const _palettePrefsKey = 'ibuild_b2b.theme.palette';
const _modePrefsKey = 'ibuild_b2b.theme.mode';

/// Persists palette + theme mode; restores from [SharedPreferences] after build.
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _restore();
    return const ThemeState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteName = prefs.getString(_palettePrefsKey);
    final modeName = prefs.getString(_modePrefsKey);

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
        await prefs.setString(_palettePrefsKey, AppPalette.ibuild.name);
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
    if (next != state) state = next;
  }

  Future<void> setPalette(AppPalette palette) async {
    state = state.copyWith(palette: palette);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_palettePrefsKey, palette.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modePrefsKey, mode.name);
  }

  Future<void> toggleBrightness() => setThemeMode(
    state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
