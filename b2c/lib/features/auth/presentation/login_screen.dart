import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/widgets/demo_entry_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_providers.dart';

/// Reads `Retry-After` off a 429 `DioException`, else `null` for any other error.
int? _rateLimitRetryAfter(Object error) {
  if (error is! DioException || error.response?.statusCode != 429) {
    return null;
  }
  final header = error.response?.headers.value('retry-after');
  return int.tryParse(header ?? '') ?? 60;
}

/// Phone entry — step 1 of the OTP sign-in flow (plan §5). Sends a code via
/// [AuthController.sendOtp], then hands off to [OtpScreen] for verification.
/// Real auth is hidden until the brand mark is tapped 5× quickly.
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
  bool _realAuthUnlocked = false;
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
    } catch (error) {
      if (!mounted) return;
      final retryAfter = _rateLimitRetryAfter(error);
      setState(
        () => _error = retryAfter != null
            ? l10n.loginRateLimitedError(retryAfter)
            : l10n.somethingWentWrong,
      );
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
                  AuthUnlockTap(
                    onUnlocked: () => setState(() => _realAuthUnlocked = true),
                    child: const BrandMark(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_realAuthUnlocked) ...[
                    const StepIndicator(step: 1, totalSteps: 2),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(l10n.welcomeTitle, style: textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.welcomeSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_realAuthUnlocked) ...[
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d+\s()-]'),
                        ),
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
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DemoEntryButton(
                    label: l10n.startDemo,
                    icon: Icons.arrow_forward,
                    variant: PillButtonVariant.accent,
                    expand: true,
                    redirect: widget.redirect,
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
