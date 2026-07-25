import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme_ext.dart';
import '../../core/widgets/auth_hero_panel.dart';
import '../../core/widgets/b2b_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../core/widgets/pill_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+998 ');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phone.text.replaceAll(RegExp(r'[\s\-()]'), '').trim();
      final requestId = await ref
          .read(authControllerProvider.notifier)
          .sendOtp(phone);
      if (!mounted) return;
      context.push('/otp', extra: {'phone': phone, 'requestId': requestId});
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context).loginSendCodeError);
    } finally {
      if (mounted) setState(() => _loading = false);
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
        Text(l10n.loginTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.loginSubtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: l10n.loginPhoneHint,
            prefixIcon: const Icon(Icons.phone_outlined),
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
          label: l10n.loginSendCode,
          expand: true,
          loading: _loading,
          onPressed: _loading ? null : _submit,
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
