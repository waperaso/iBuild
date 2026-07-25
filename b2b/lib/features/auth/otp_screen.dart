import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/auth_hero_panel.dart';
import '../../core/widgets/b2b_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth.dart';

/// Default client-side gap between resend taps — well inside the server's
/// OTP-send rate limit, so a normal retry never hits 429.
const _resendCooldownSeconds = 30;

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.requestId});

  final String phone;
  final String requestId;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  // A stale/expired requestId otherwise has no recovery path other than
  // backing out to the login screen and re-entering the phone number.
  late String _requestId = widget.requestId;
  bool _resending = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _code.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = _resendCooldownSeconds]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(requestId: _requestId, code: _code.text.trim());
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context).otpInvalidError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final requestId = await ref
          .read(authControllerProvider.notifier)
          .sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _requestId = requestId;
        _code.clear();
      });
      _startCooldown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.otpResendSuccess)));
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        final retryAfter = int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        );
        _startCooldown(retryAfter ?? _resendCooldownSeconds);
      }
      final body = error.response?.data;
      final serverMessage = body is Map && body['error'] is Map
          ? (body['error'] as Map)['message']?.toString()
          : null;
      if (mounted) {
        setState(
          () => _error = l10n.otpResendError(
            serverMessage ?? error.message ?? error.toString(),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = l10n.otpResendError('$e'));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final form = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const B2bBrand(),
        const SizedBox(height: AppSpacing.xxl),
        Text(l10n.otpTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.otpSentTo(widget.phone),
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _code,
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            hintText: l10n.otpHint,
            counterText: '',
            // The fixed dev OTP (`123456`) is only ever a fallback when
            // Eskiz isn't configured; never surface that hint in release
            // builds where it would read as a real bypass.
            helperText: kDebugMode ? l10n.otpDevHelper : null,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: l10n.otpVerify,
          expand: true,
          loading: _loading,
          onPressed: _loading ? null : _verify,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text(
              l10n.otpResendPrompt,
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
            if (_resending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _cooldownSeconds > 0 ? null : _resend,
                child: Text(
                  _cooldownSeconds > 0
                      ? l10n.otpResendCountdown(_cooldownSeconds)
                      : l10n.otpResendAction,
                ),
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= AppBreakpoints.tablet;
                final scrollable = SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: form,
                );
                if (!wide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: scrollable,
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeroPanel(),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: scrollable,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }
}
