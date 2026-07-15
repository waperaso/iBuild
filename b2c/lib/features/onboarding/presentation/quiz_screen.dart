import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/constrained_body.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/buyer_persona.dart';
import '../providers/quiz_providers.dart';

/// Gamified onboarding quiz (Phase 2, frontend-only mock). Walks the buyer
/// through four quick questions, derives a [BuyerPersona], stores it locally
/// via [QuizController], and renders a mock on-device AI preview.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const _questionCount = 4;

  /// 0 = intro, 1..4 = questions, 5 = result.
  int _step = 0;

  QuizGoal? _goal;
  QuizLocationPref? _location;
  QuizTimeline? _timeline;
  QuizPriority? _priority;
  QuizResult? _result;

  void _advance() => setState(() => _step += 1);
  void _back() => setState(() => _step -= 1);

  Future<void> _finish() async {
    final answers = QuizAnswers(
      goal: _goal!,
      location: _location!,
      timeline: _timeline!,
      priority: _priority!,
    );
    final result = await ref
        .read(quizControllerProvider.notifier)
        .save(answers);
    if (!mounted) return;
    setState(() {
      _result = result;
      _step = _questionCount + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).quizSavedSnackbar)),
    );
  }

  void _restart() {
    setState(() {
      _step = 1;
      _goal = null;
      _location = null;
      _timeline = null;
      _priority = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_step >= 1 && _step <= _questionCount
              ? Icons.arrow_back
              : Icons.close),
          onPressed: () {
            if (_step >= 2 && _step <= _questionCount) {
              _back();
            } else {
              context.canPop() ? context.pop() : context.go('/home');
            }
          },
        ),
        title: Text(l10n.quizTitle),
      ),
      body: ConstrainedBody(
        maxWidth: 560,
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppDurations.enter,
          child: _buildStep(context, l10n),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    if (_step == 0) {
      return _IntroStep(key: const ValueKey('intro'), onStart: _advance);
    }
    if (_step == _questionCount + 1 && _result != null) {
      return _ResultStep(
        key: const ValueKey('result'),
        result: _result!,
        onRetake: _restart,
        onDone: () => context.go('/home'),
      );
    }
    return _questionStep(context, l10n);
  }

  Widget _questionStep(BuildContext context, AppLocalizations l10n) {
    switch (_step) {
      case 1:
        return _QuestionStep<QuizGoal>(
          key: const ValueKey('q1'),
          step: _step,
          totalSteps: _questionCount,
          question: l10n.quizGoalQuestion,
          options: QuizGoal.values,
          selected: _goal,
          labelFor: (v) => _goalLabel(l10n, v),
          iconFor: _goalIcon,
          onSelected: (v) {
            setState(() => _goal = v);
            _advance();
          },
        );
      case 2:
        return _QuestionStep<QuizLocationPref>(
          key: const ValueKey('q2'),
          step: _step,
          totalSteps: _questionCount,
          question: l10n.quizLocationQuestion,
          options: QuizLocationPref.values,
          selected: _location,
          labelFor: (v) => _locationLabel(l10n, v),
          iconFor: _locationIcon,
          onSelected: (v) {
            setState(() => _location = v);
            _advance();
          },
        );
      case 3:
        return _QuestionStep<QuizTimeline>(
          key: const ValueKey('q3'),
          step: _step,
          totalSteps: _questionCount,
          question: l10n.quizTimelineQuestion,
          options: QuizTimeline.values,
          selected: _timeline,
          labelFor: (v) => _timelineLabel(l10n, v),
          iconFor: _timelineIcon,
          onSelected: (v) {
            setState(() => _timeline = v);
            _advance();
          },
        );
      default:
        return _QuestionStep<QuizPriority>(
          key: const ValueKey('q4'),
          step: _step,
          totalSteps: _questionCount,
          question: l10n.quizPriorityQuestion,
          options: QuizPriority.values,
          selected: _priority,
          labelFor: (v) => _priorityLabel(l10n, v),
          iconFor: _priorityIcon,
          onSelected: (v) {
            setState(() => _priority = v);
            _finish();
          },
        );
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: colors.accent, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.quizIntroTitle, style: textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.quizIntroBody,
            style: textTheme.bodyLarge?.copyWith(color: colors.inkMuted),
          ),
          const Spacer(),
          PillButton(
            label: l10n.quizStartAction,
            icon: Icons.arrow_forward,
            expand: true,
            onPressed: onStart,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _QuestionStep<T> extends StatelessWidget {
  const _QuestionStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.question,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.iconFor,
    required this.onSelected,
  });

  final int step;
  final int totalSteps;
  final String question;
  final List<T> options;
  final T? selected;
  final String Function(T) labelFor;
  final IconData Function(T) iconFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        StepIndicator(step: step, totalSteps: totalSteps),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.quizStepCounter(step, totalSteps),
          style: textTheme.labelMedium?.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(question, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xl),
        for (final option in options) ...[
          _OptionCard(
            label: labelFor(option),
            icon: iconFor(option),
            selected: option == selected,
            onTap: () => onSelected(option),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      color: selected ? colors.accent.withValues(alpha: 0.16) : colors.surface,
      border: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? colors.accent : colors.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? colors.accent : colors.outline,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    super.key,
    required this.result,
    required this.onRetake,
    required this.onDone,
  });

  final QuizResult result;
  final VoidCallback onRetake;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final answers = result.answers;
    final answerLabels = [
      _goalLabel(l10n, answers.goal),
      _locationLabel(l10n, answers.location),
      _timelineLabel(l10n, answers.timeline),
      _priorityLabel(l10n, answers.priority),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.quizResultEyebrow,
          style: textTheme.labelLarge?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(_personaIcon(result.persona), color: colors.accent, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _personaLabel(l10n, result.persona),
                style: textTheme.displaySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _personaDescription(l10n, result.persona),
          style: textTheme.bodyLarge?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          elevated: true,
          color: colors.heroSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colors.onHeroSurface,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.quizPreviewTitle,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onHeroSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.quizPreviewPromptLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onHeroSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                answerLabels.join('  ·  '),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onHeroSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.quizPreviewBody(_personaLabel(l10n, result.persona)),
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onHeroSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: l10n.quizDoneAction,
          icon: Icons.explore_outlined,
          expand: true,
          onPressed: onDone,
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: l10n.quizRetakeAction,
          variant: PillButtonVariant.outline,
          expand: true,
          onPressed: onRetake,
        ),
      ],
    );
  }
}

String _goalLabel(AppLocalizations l10n, QuizGoal v) => switch (v) {
  QuizGoal.budget => l10n.quizGoalBudget,
  QuizGoal.family => l10n.quizGoalFamily,
  QuizGoal.investment => l10n.quizGoalInvestment,
  QuizGoal.luxury => l10n.quizGoalLuxury,
};

IconData _goalIcon(QuizGoal v) => switch (v) {
  QuizGoal.budget => Icons.savings_outlined,
  QuizGoal.family => Icons.family_restroom,
  QuizGoal.investment => Icons.trending_up,
  QuizGoal.luxury => Icons.diamond_outlined,
};

String _locationLabel(AppLocalizations l10n, QuizLocationPref v) =>
    switch (v) {
      QuizLocationPref.cityCenter => l10n.quizLocationCityCenter,
      QuizLocationPref.quietSuburb => l10n.quizLocationQuietSuburb,
      QuizLocationPref.businessDistrict => l10n.quizLocationBusinessDistrict,
      QuizLocationPref.upAndComing => l10n.quizLocationUpAndComing,
    };

IconData _locationIcon(QuizLocationPref v) => switch (v) {
  QuizLocationPref.cityCenter => Icons.location_city,
  QuizLocationPref.quietSuburb => Icons.park_outlined,
  QuizLocationPref.businessDistrict => Icons.business_center_outlined,
  QuizLocationPref.upAndComing => Icons.rocket_launch_outlined,
};

String _timelineLabel(AppLocalizations l10n, QuizTimeline v) => switch (v) {
  QuizTimeline.readyNow => l10n.quizTimelineReadyNow,
  QuizTimeline.offplanOk => l10n.quizTimelineOffplanOk,
  QuizTimeline.flexible => l10n.quizTimelineFlexible,
};

IconData _timelineIcon(QuizTimeline v) => switch (v) {
  QuizTimeline.readyNow => Icons.bolt_outlined,
  QuizTimeline.offplanOk => Icons.construction_outlined,
  QuizTimeline.flexible => Icons.schedule_outlined,
};

String _priorityLabel(AppLocalizations l10n, QuizPriority v) => switch (v) {
  QuizPriority.price => l10n.quizPriorityPrice,
  QuizPriority.space => l10n.quizPrioritySpace,
  QuizPriority.amenities => l10n.quizPriorityAmenities,
  QuizPriority.location => l10n.quizPriorityLocation,
};

IconData _priorityIcon(QuizPriority v) => switch (v) {
  QuizPriority.price => Icons.sell_outlined,
  QuizPriority.space => Icons.crop_free,
  QuizPriority.amenities => Icons.pool_outlined,
  QuizPriority.location => Icons.place_outlined,
};

String _personaLabel(AppLocalizations l10n, BuyerPersona v) => switch (v) {
  BuyerPersona.firstTimeBuyer => l10n.quizPersonaFirstTimeBuyer,
  BuyerPersona.familyNester => l10n.quizPersonaFamilyNester,
  BuyerPersona.investor => l10n.quizPersonaInvestor,
  BuyerPersona.luxurySeeker => l10n.quizPersonaLuxurySeeker,
};

String _personaDescription(AppLocalizations l10n, BuyerPersona v) =>
    switch (v) {
      BuyerPersona.firstTimeBuyer => l10n.quizPersonaFirstTimeBuyerDesc,
      BuyerPersona.familyNester => l10n.quizPersonaFamilyNesterDesc,
      BuyerPersona.investor => l10n.quizPersonaInvestorDesc,
      BuyerPersona.luxurySeeker => l10n.quizPersonaLuxurySeekerDesc,
    };

IconData _personaIcon(BuyerPersona v) => switch (v) {
  BuyerPersona.firstTimeBuyer => Icons.key_outlined,
  BuyerPersona.familyNester => Icons.family_restroom,
  BuyerPersona.investor => Icons.trending_up,
  BuyerPersona.luxurySeeker => Icons.diamond_outlined,
};
