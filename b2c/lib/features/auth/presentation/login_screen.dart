import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_providers.dart';

/// Phone entry — step 1 of the OTP sign-in flow (plan §5). Sends a code via
/// [AuthController.sendOtp], then hands off to [OtpScreen] for verification.
/// Guest browsing stays fully available without going through this screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirect});

  /// Where to land after a successful sign-in (e.g. the lead form the user
  /// was trying to submit as a guest). Defaults to `/home` when absent.
  final String? redirect;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+998 ');
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context);
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = l10n.phoneRequiredError);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final requestId = await ref
          .read(authControllerProvider.notifier)
          .sendOtp(phone);
      if (!mounted) return;
      context.push(
        Uri(
          path: '/otp',
          queryParameters: {
            'requestId': requestId,
            'phone': phone,
            if (widget.redirect != null) 'redirect': widget.redirect,
          },
        ).toString(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(),
                  const SizedBox(height: AppSpacing.lg),
                  const StepIndicator(step: 1, totalSteps: 2),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.welcomeTitle, style: textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.welcomeSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.phoneHint,
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: l10n.sendCode,
                    expand: true,
                    loading: _sending,
                    onPressed: _sending ? null : _sendCode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
