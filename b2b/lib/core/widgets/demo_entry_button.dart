import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../theme/app_dimens.dart';
import '../widgets/demo_mode.dart';
import '../widgets/pill_button.dart';
import '../../features/auth/auth.dart';
import '../../l10n/gen/app_localizations.dart';

class DemoEntryButton extends ConsumerStatefulWidget {
  const DemoEntryButton({
    super.key,
    this.expand = false,
    this.label,
    this.icon = Icons.play_circle_outline,
    this.variant = PillButtonVariant.outline,
  });

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
      final existing = ref.read(authControllerProvider).value;
      if (existing == null || !existing.isDemo) {
        await ref.read(authControllerProvider.notifier).signInAsDemo();
      } else {
        DemoSession.activate();
      }
      if (!mounted) return;
      await showDemoModeDialog(context);
      if (!mounted) return;
      context.go('/platform');
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
    return PillButton(
      label: widget.label ?? l10n.demoButton,
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
        DemoEntryButton(expand: expand),
      ],
    );
  }
}
