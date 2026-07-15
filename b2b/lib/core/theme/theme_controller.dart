import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
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

/// A named palette the app can switch to at runtime. Add new entries here (and
/// a matching [AppColors] light/dark pair under `color_schemes/`) to expand the
/// theme catalog. The first entry is the default palette (see
/// [ThemeState.palette]).
///
/// [meridian] is the default B2B palette; [aurora] and [lime] remain for
/// continuity with the earlier catalog, and the remaining twelve mirror the
/// shared B2C/B2B scheme set so both apps offer the same fifteen choices.
enum AppPalette {
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
/// and the settings screen mutates it to switch schemes live.
class ThemeState {
  const ThemeState({
    this.palette = AppPalette.meridian,
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

/// Holds the active palette + theme mode and persists both to
/// [SharedPreferences] so the admin's choice survives a restart. The selection
/// is restored asynchronously after first build (the default paints instantly,
/// then swaps to the saved value once the read resolves).
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
      for (final p in AppPalette.values) {
        if (p.name == paletteName) {
          next = next.copyWith(palette: p);
          break;
        }
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
