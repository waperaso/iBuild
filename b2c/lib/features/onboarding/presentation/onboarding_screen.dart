import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/language_menu.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/theme_brightness_menu.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Brand isometric skyline asset for the onboarding hero.
const _heroImageAsset = 'assets/images/onboarding_hero.png';

const _brandName = 'iBuild';

/// First-run landing: full-bleed hero + copy column on desktop; stacked on mobile.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.isMobile ? colors.background : colors.heroSurface,
      body: context.isMobile
          ? const _MobileHero()
          : const _DesktopHero(),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.onDark, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final markSize = compact ? 40.0 : 52.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize, onDark: onDark),
        SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          _brandName,
          style: (compact ? textTheme.headlineSmall : textTheme.displayMedium)
              ?.copyWith(
                color: onDark ? colors.onHeroSurface : colors.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1,
              ),
        ),
      ],
    );
  }
}

/// Tagline under the wordmark (part of the brand lockup).
class _Slogan extends StatelessWidget {
  const _Slogan({required this.onDark, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final fg = onDark
        ? colors.onHeroSurface.withValues(alpha: 0.82)
        : colors.inkMuted;

    return Text(
      l10n.onboardingSlogan,
      style:
          (compact
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final fg = onDark
        ? colors.onHeroSurface.withValues(alpha: 0.72)
        : colors.inkMuted;

    return Row(
      children: [
        Icon(Icons.star_rounded, size: 16, color: colors.accentSecondary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            l10n.onboardingTrustBadge,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final start = PillButton(
      label: l10n.start,
      icon: Icons.arrow_forward,
      expand: expand,
      onPressed: () => context.go('/home'),
    );
    final signIn = PillButton(
      label: l10n.signIn,
      variant: PillButtonVariant.outline,
      expand: expand,
      onPressed: () => context.go('/login'),
    );

    if (expand) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          start,
          const SizedBox(height: AppSpacing.sm),
          signIn,
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [start, signIn],
    );
  }
}

class _QuizLink extends StatelessWidget {
  const _QuizLink({required this.onDark});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final fg = onDark
        ? colors.onHeroSurface.withValues(alpha: 0.85)
        : colors.inkMuted;

    return TextButton.icon(
      onPressed: () => context.push('/quiz'),
      icon: Icon(Icons.auto_awesome, size: 18, color: fg),
      label: Text(
        l10n.quizEntryAction,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
      ),
      style: TextButton.styleFrom(
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

/// Language + theme pills for the onboarding header.
class _OnboardingPrefs extends StatelessWidget {
  const _OnboardingPrefs({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LanguageMenu(compact: compact),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        ThemeBrightnessMenu(compact: compact),
      ],
    );
  }
}

/// Hero artwork — a static local asset now (see [_heroImageAsset]), so there
/// is no placeholder/shimmer flash and no network dependency on this, the
/// very first screen a cold start renders.
class _BreathingHeroPhoto extends StatelessWidget {
  const _BreathingHeroPhoto();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _heroImageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 1400 ? 560.0 : 480.0;
    final horizontalPad = width >= 1400 ? 72.0 : 48.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        const _BreathingHeroPhoto(),
        // Left-side gradient for text contrast over the hero photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.heroSurface.withValues(alpha: 0.94),
                colors.heroSurface.withValues(alpha: 0.78),
                colors.heroSurface.withValues(alpha: 0.28),
                colors.heroSurface.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.32, 0.58, 0.82],
            ),
          ),
        ),
        // Bottom fade on the hero photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                colors.heroSurface.withValues(alpha: 0.45),
                colors.heroSurface.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.35],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              AppSpacing.xxl,
              horizontalPad,
              AppSpacing.xxl,
            ),
            child: Stack(
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: FadeSlideIn(
                    index: 0,
                    delayStep: Duration(milliseconds: 70),
                    child: _OnboardingPrefs(compact: true),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMax),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FadeSlideIn(
                            index: 0,
                            delayStep: Duration(milliseconds: 70),
                            child: _BrandLockup(onDark: true),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const FadeSlideIn(
                            index: 1,
                            delayStep: Duration(milliseconds: 70),
                            child: _Slogan(onDark: true),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FadeSlideIn(
                            index: 2,
                            delayStep: const Duration(milliseconds: 70),
                            child: Text(
                              l10n.onboardingEyebrow,
                              style: textTheme.displayLarge?.copyWith(
                                color: colors.onHeroSurface,
                                fontSize: width >= 1400 ? 44 : 38,
                                height: 1.15,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FadeSlideIn(
                            index: 3,
                            delayStep: const Duration(milliseconds: 70),
                            child: Text(
                              l10n.onboardingDescription,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.onHeroSurface.withValues(
                                  alpha: 0.78,
                                ),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          const FadeSlideIn(
                            index: 4,
                            delayStep: Duration(milliseconds: 70),
                            child: _PrimaryActions(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const FadeSlideIn(
                            index: 5,
                            delayStep: Duration(milliseconds: 70),
                            child: _QuizLink(onDark: true),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          const FadeSlideIn(
                            index: 6,
                            delayStep: Duration(milliseconds: 70),
                            child: _TrustLine(onDark: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FadeSlideIn(
              index: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _BrandLockup(onDark: false, compact: true),
                  ),
                  _OnboardingPrefs(compact: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const FadeSlideIn(
              index: 1,
              child: _Slogan(onDark: false, compact: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              index: 2,
              child: Text(
                l10n.onboardingEyebrow,
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FadeSlideIn(
                index: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _BreathingHeroPhoto(),
                      // Bottom gradient under CTAs.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              colors.heroSurface.withValues(alpha: 0.4),
                              colors.heroSurface.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const FadeSlideIn(
              index: 4,
              child: _PrimaryActions(expand: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            const FadeSlideIn(
              index: 5,
              child: Center(child: _QuizLink(onDark: false)),
            ),
          ],
        ),
      ),
    );
  }
}
