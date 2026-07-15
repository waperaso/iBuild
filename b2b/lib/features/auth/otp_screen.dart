import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/b2b_brand.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth.dart';

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

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(requestId: widget.requestId, code: _code.text.trim());
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context).otpInvalidError);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  const B2bBrand(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(l10n.otpTitle, style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.otpSentTo(widget.phone),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
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
                      // The fixed dev OTP (`123456`) is only ever a fallback
                      // when Eskiz isn't configured; never surface that hint in
                      // release builds where it would read as a real bypass.
                      helperText: kDebugMode ? l10n.otpDevHelper : null,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PillButton(
                    label: l10n.otpVerify,
                    expand: true,
                    loading: _loading,
                    onPressed: _loading ? null : _verify,
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
