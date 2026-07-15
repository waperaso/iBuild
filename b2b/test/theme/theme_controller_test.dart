import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild_b2b/core/theme/app_colors.dart';
import 'package:ibuild_b2b/core/theme/app_theme.dart';
import 'package:ibuild_b2b/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the event loop a few times so an async `_restore()` (which awaits
/// `SharedPreferences.getInstance()`) has a chance to settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('catalog exposes the full set of 15 palettes', () {
    expect(AppPalette.values.length, 15);
    // Meridian stays the default/first entry.
    expect(AppPalette.values.first, AppPalette.meridian);
    // The twelve new schemes are all present.
    for (final name in const [
      'sapphire',
      'emerald',
      'sunset',
      'rose',
      'graphite',
      'plum',
      'ocean',
      'sand',
      'crimson',
      'midnight',
      'mint',
      'amethyst',
    ]) {
      expect(
        AppPalette.values.any((p) => p.name == name),
        isTrue,
        reason: 'missing palette "$name"',
      );
    }
  });

  test('defaults to Meridian in light mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(themeControllerProvider);
    expect(state.palette, AppPalette.meridian);
    expect(state.themeMode, ThemeMode.light);
  });

  test('setPalette updates state and persists the choice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeControllerProvider.notifier)
        .setPalette(AppPalette.sapphire);

    expect(container.read(themeControllerProvider).palette, AppPalette.sapphire);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ibuild_b2b.theme.palette'), 'sapphire');
  });

  test('toggleBrightness flips the theme mode and persists it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(themeControllerProvider.notifier).toggleBrightness();

    expect(container.read(themeControllerProvider).themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ibuild_b2b.theme.mode'), 'dark');
  });

  test('restores a persisted palette + mode on first build', () async {
    SharedPreferences.setMockInitialValues({
      'ibuild_b2b.theme.palette': 'emerald',
      'ibuild_b2b.theme.mode': 'dark',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Build the provider, then let the async restore settle.
    container.read(themeControllerProvider);
    await _settle();

    final state = container.read(themeControllerProvider);
    expect(state.palette, AppPalette.emerald);
    expect(state.themeMode, ThemeMode.dark);
  });

  test('every palette builds a legible light + dark ThemeData', () {
    for (final palette in AppPalette.values) {
      final light = buildAppTheme(palette.light);
      final dark = buildAppTheme(palette.dark);
      expect(light.brightness, Brightness.light, reason: palette.label);
      expect(dark.brightness, Brightness.dark, reason: palette.label);
      // Palette tokens are wired through as a theme extension.
      expect(light.extension<AppColors>(), isNotNull, reason: palette.label);
      expect(dark.extension<AppColors>(), isNotNull, reason: palette.label);
    }
  });
}
