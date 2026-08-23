import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_dimens.dart';
import '../widgets/demo_mode.dart';
import '../widgets/pill_button.dart';
import '../../features/auth/auth.dart';
import '../../l10n/gen/app_localizations.dart';

/// Demo login profile for B2B reviewers.
enum DemoLoginProfile {
  platform,
  residence,
}

extension on DemoLoginProfile {
  String get apiProfile => switch (this) {
    DemoLoginProfile.platform => 'b2b_platform',
    DemoLoginProfile.residence => 'b2b_residence',
  };

  String get homePath => switch (this) {
    DemoLoginProfile.platform => '/platform',
    DemoLoginProfile.residence => '/residence',
  };
}

class DemoEntryButton extends ConsumerStatefulWidget {
  const DemoEntryButton({
    super.key,
    required this.profile,
    this.expand = false,
    this.label,
    this.icon = Icons.play_circle_outline,
    this.variant = PillButtonVariant.outline,
  });

  final DemoLoginProfile profile;
  final bool expand;
  final String? label;
  final IconData icon;
  final PillButtonVariant variant;

  @override
  ConsumerState<DemoEntryButton> createState() => _DemoEntryButtonState();
}

class _DemoEntryButtonState extends ConsumerState<DemoEntryButton> {
  bool _loading = false;

  Future<void> _enterDemo() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInAsDemo(profile: widget.profile.apiProfile);
      if (!mounted) return;
      await showDemoModeDialog(context);
      if (!mounted) return;
      context.go(widget.profile.homePath);
    } catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.loginSendCodeError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultLabel = switch (widget.profile) {
      DemoLoginProfile.platform => l10n.signInDemoPlatform,
      DemoLoginProfile.residence => l10n.signInDemoResidence,
    };
    return PillButton(
      label: widget.label ?? defaultLabel,
      icon: widget.icon,
      variant: widget.variant,
      expand: widget.expand,
      loading: _loading,
      onPressed: _loading ? null : _enterDemo,
    );
  }
}

class DemoEntrySection extends StatelessWidget {
  const DemoEntrySection({super.key, this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          expand ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.md),
        DemoEntryButton(
          profile: DemoLoginProfile.platform,
          expand: expand,
          icon: Icons.admin_panel_settings_outlined,
          variant: PillButtonVariant.accent,
        ),
        const SizedBox(height: AppSpacing.sm),
        DemoEntryButton(
          profile: DemoLoginProfile.residence,
          expand: expand,
          icon: Icons.apartment_outlined,
          variant: PillButtonVariant.outline,
        ),
      ],
    );
  }
}
