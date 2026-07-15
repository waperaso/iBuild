import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_providers.dart';

/// 6-digit code entry — step 2 of the OTP sign-in flow (plan §5). On
/// success, establishes the session via [AuthController.signIn] and
/// navigates to `/home`.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.requestId, required this.phone});

  final String requestId;
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late String _requestId = widget.requestId;
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            requestId: _requestId,
            code: _code.text.trim(),
            phone: widget.phone,
          );
      if (!mounted) return;
      context.go('/home');
    } catch (error, stack) {
      // The banner stays generic (matches the real backend's opaque
      // INVALID_CODE error), but log the real cause — a storage or network
      // failure looks identical to a bad code otherwise and is much harder
      // to diagnose from the UI alone.
      debugPrint('OtpScreen: sign-in failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = l10n.invalidCodeError);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final requestId = await ref
          .read(authControllerProvider.notifier)
          .sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _requestId = requestId;
        _error = null;
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(backgroundColor: colors.background, elevation: 0),
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
                  const StepIndicator(step: 2, totalSteps: 2),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.otpTitle, style: textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.otpSubtitle(widget.phone),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: kDebugMode ? '123456' : null,
                      counterText: '',
                      errorText: _error,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.otpDevHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: l10n.verifyCode,
                    expand: true,
                    loading: _verifying,
                    onPressed: _verifying ? null : _verify,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _resending ? null : _resend,
                        child: Text(l10n.resendCode),
                      ),
                    ],
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
