import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../l10n/gen/app_localizations.dart';

const _heroImageUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Modern_Tashkent._Skyline.jpg/1280px-Modern_Tashkent._Skyline.jpg';

const _brandName = 'iBuild';

/// Immersive first-run landing for B2C.
///
/// Desktop/tablet: full-bleed city photography with a left reading column —
/// brand first, one headline, one supporting line, clear CTA hierarchy.
/// Mobile: stacked brand → copy → photo → actions, still brand-led.
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

/// Hero photo. On Flutter web the continuous scale animation burned frames
/// for little gain, so the image is static there.
class _BreathingHeroPhoto extends StatelessWidget {
  const _BreathingHeroPhoto();

  @override
  Widget build(BuildContext context) {
    return const AppNetworkImage(
      url: _heroImageUrl,
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
        // Left reading wash — keeps type crisp without boxing the photo.
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
        // Bottom vignette so the skyline still reads as place, not a crop.
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
            child: Align(
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
                      const SizedBox(height: AppSpacing.xxxl),
                      FadeSlideIn(
                        index: 1,
                        delayStep: const Duration(milliseconds: 70),
                        child: Text(
                          l10n.onboardingEyebrow,
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.onHeroSurface.withValues(alpha: 0.7),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        index: 2,
                        delayStep: const Duration(milliseconds: 70),
                        child: Text(
                          l10n.onboardingHeadline,
                          style: textTheme.displayLarge?.copyWith(
                            color: colors.onHeroSurface,
                            fontSize: width >= 1400 ? 56 : 48,
                            height: 1.05,
                            letterSpacing: -1.1,
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
                            color: colors.onHeroSurface.withValues(alpha: 0.78),
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
              child: _BrandLockup(onDark: false, compact: true),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              index: 1,
              child: Text(
                l10n.onboardingEyebrow,
                style: textTheme.labelLarge?.copyWith(color: colors.inkMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              index: 2,
              child: Text(
                l10n.onboardingHeadline,
                style: textTheme.displayMedium,
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
                      const AppNetworkImage(
                        url: _heroImageUrl,
                        width: double.infinity,
                      ),
                      // Soft bottom fade so the photo meets the CTAs cleanly.
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
