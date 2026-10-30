import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../brand.dart';
import '../l10n.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  var _needCredentials = false;
  var _demoOn = false;
  var _asked = false;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadDemo() async {
    final on = await SessionScope.of(context).api.demoEnabled();
    if (mounted && on) setState(() => _demoOn = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    _loadDemo();
  }

  Future<void> _submit() async {
    final login = _login.text.trim();
    final password = _password.text;
    if (login.isEmpty || password.isEmpty) {
      setState(() => _needCredentials = true);
      return;
    }
    setState(() => _needCredentials = false);
    await SessionScope.of(context).login(login, password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = SessionScope.of(context);
    final copy = LocaleScope.copy(context);
    final error = _needCredentials
        ? copy.enterCredentials
        : (session.error == null ? null : copy.known(session.error!));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.heroSurface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrandLockup(
                            size: 64,
                            onDark: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  IBuildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          copy.signInTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          key: const Key('login-field'),
                          controller: _login,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: copy.loginLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          key: const Key('password-field'),
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: copy.passwordLabel,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          ErrorNote(message: error),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          key: const Key('login-button'),
                          label: copy.signInButton,
                          busy: session.busy,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(color: colors.outline),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          copy.registerHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          key: const Key('register-button'),
                          onPressed: () => context.go('/register'),
                          child: Text(copy.registerLink),
                        ),
                      ],
                    ),
                  ),
                  if (_demoOn) ...[
                    const SizedBox(height: AppSpacing.lg),
                    IBuildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(copy.demoTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            copy.demoHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final role in const ['developer', 'contractor', 'tech', 'bank', 'admin'])
                                OutlinedButton(
                                  key: Key('demo-$role'),
                                  onPressed: session.busy ? null : () => session.demoLogin(role),
                                  child: Text(copy.demoRole(role)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: LanguageSwitch()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
