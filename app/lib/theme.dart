import 'package:flutter/material.dart';

import 'locale_store.dart';

/// Official iBuild brand palette: navy "IB" on cool gray.
@immutable
class IBuildColors extends ThemeExtension<IBuildColors> {
  const IBuildColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.onAccent,
    required this.heroSurface,
    required this.onHeroSurface,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color onAccent;
  final Color heroSurface;
  final Color onHeroSurface;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = IBuildColors(
    background: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF2F6),
    accent: Color(0xFF0B1F33),
    onAccent: Color(0xFFFFFFFF),
    heroSurface: Color(0xFF0B1F33),
    onHeroSurface: Color(0xFFE7EDF3),
    ink: Color(0xFF101820),
    inkMuted: Color(0xFF667485),
    outline: Color(0xFFE4E9EF),
    success: Color(0xFF1F7A4D),
    warning: Color(0xFFB86E09),
    danger: Color(0xFFC24132),
  );

  static const dark = IBuildColors(
    background: Color(0xFF101418),
    surface: Color(0xFF1B222B),
    surfaceAlt: Color(0xFF242C36),
    accent: Color(0xFF7EB6E6),
    onAccent: Color(0xFF0B1F33),
    heroSurface: Color(0xFF0B1F33),
    onHeroSurface: Color(0xFFE7EDF3),
    ink: Color(0xFFE8EEF4),
    inkMuted: Color(0xFF9AABBA),
    outline: Color(0xFF2C3642),
    success: Color(0xFF3DDC97),
    warning: Color(0xFFE2A84B),
    danger: Color(0xFFFF8A7A),
  );

  @override
  IBuildColors copyWith() => this;

  @override
  IBuildColors lerp(IBuildColors? other, double t) => this;
}

extension IBuildColorsContext on BuildContext {
  IBuildColors get colors => Theme.of(this).extension<IBuildColors>()!;
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract class AppRadii {
  static const double input = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double card = 18;
  static const double pill = 999;
}

/// Phone layout below this width. Matches the week-1 adaptation rule.
const double kPhoneBreakpoint = 600;

/// Below this width the side menu is an icon rail and the page uses the
/// rest of the screen. Covers portrait and landscape tablets, including
/// an 11-inch iPad. A 1280-wide desktop keeps the labeled menu.
const double kTabletBreakpoint = 1280;

abstract class AppShadows {
  static List<BoxShadow> soft(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> raised(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
}

abstract class AppTypography {
  static const fontFamily = 'PlusJakartaSans';

  static TextTheme textTheme(Color ink) {
    final base = ThemeData.light().textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: ink,
      displayColor: ink,
    );
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NoMotion extends PageTransitionsBuilder {
  const _NoMotion();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

const _noMotion = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _NoMotion(),
    TargetPlatform.iOS: _NoMotion(),
    TargetPlatform.macOS: _NoMotion(),
    TargetPlatform.linux: _NoMotion(),
    TargetPlatform.windows: _NoMotion(),
    TargetPlatform.fuchsia: _NoMotion(),
  },
);

ButtonStyle _still(ButtonStyle style) {
  return style.copyWith(animationDuration: Duration.zero);
}

ThemeData buildIBuildTheme(IBuildColors colors) {
  final text = AppTypography.textTheme(colors.ink);
  final brightness = colors == IBuildColors.dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: colors.background,
    textTheme: text,
    pageTransitionsTheme: _noMotion,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: brightness == Brightness.dark ? const Color(0x14FFFFFF) : const Color(0x140B1F33),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
    extensions: [colors],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.ink,
      error: colors.danger,
      onError: colors.onAccent,
      outline: colors.outline,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _still(FilledButton.styleFrom()),
    ),
    textButtonTheme: TextButtonThemeData(style: _still(TextButton.styleFrom())),
    iconButtonTheme: IconButtonThemeData(style: _still(IconButton.styleFrom())),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: colors.accent, width: 1.4),
      ),
      labelStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
    ),
  );
}

enum AppTheme { light, dark }

class ThemeController extends ChangeNotifier {
  ThemeController() : dark = readStoredTheme() == 'dark';

  bool dark;

  ThemeMode get mode => dark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    dark = !dark;
    writeStoredTheme(dark ? 'dark' : 'light');
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is missing');
    return scope!.notifier!;
  }
}
