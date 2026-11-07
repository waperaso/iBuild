import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kit.dart';

/// Changing the password. Shown by itself, before anything else, to a person
/// who signed in with a temporary password, and reachable from the top bar.
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = Tx.of(context);
    final session = SessionScope.of(context);
    if (_next.text.length < 10) {
      setState(() => _error = t('Введите новый пароль длиной не менее 10 символов.', 'Enter a new password with at least 10 characters.', 'Kamida 10 belgidan iborat yangi parol kiriting.'));
      return;
    }
    if (_next.text != _repeat.text) {
      setState(() => _error = t('Пароли не совпадают.', 'The passwords do not match.', 'Parollar mos kelmadi.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Пароль изменён.', 'Password changed.', 'Parol o‘zgartirildi.'))));
      context.go('/home');
    } on ApiException catch (failure) {
      if (mounted) setState(() => _error = errorText(context, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final session = SessionScope.of(context);
    final forced = session.user?.mustChangePassword ?? false;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: IBuildCard(
              child: Column(
                key: const Key('password-frame'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('Смена пароля', 'Change password', 'Parolni almashtirish'), style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    forced
                        ? t('Замените временный пароль, чтобы открыть кабинет.', 'Replace your temporary password to open your workspace.', 'Kabinetga kirish uchun vaqtinchalik parolni almashtiring.')
                        : t('После смены пароля на других устройствах нужно войти заново.', 'After changing your password, sign in again on your other devices.', 'Parolni almashtirgach, boshqa qurilmalarda qayta kiring.'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(key: const Key('pw-current'), controller: _current, obscureText: true, decoration: InputDecoration(labelText: t('Текущий пароль', 'Current password', 'Joriy parol'))),
                  const SizedBox(height: AppSpacing.md),
                  TextField(key: const Key('pw-new'), controller: _next, obscureText: true, decoration: InputDecoration(labelText: t('Новый пароль', 'New password', 'Yangi parol'), helperText: t('Не короче 10 символов', 'At least 10 characters', 'Kamida 10 belgi'))),
                  const SizedBox(height: AppSpacing.md),
                  TextField(key: const Key('pw-repeat'), controller: _repeat, obscureText: true, decoration: InputDecoration(labelText: t('Повторите новый пароль', 'Repeat the new password', 'Yangi parolni takrorlang'))),
                  if (_error != null) ...[const SizedBox(height: AppSpacing.md), ErrorNote(message: _error!)],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(key: const Key('pw-save'), label: t('Сохранить пароль', 'Save password', 'Parolni saqlash'), busy: _busy, onPressed: _save),
                  if (!forced) TextButton(key: const Key('pw-cancel'), onPressed: () => context.go('/home'), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
                  if (forced) TextButton(key: const Key('pw-logout'), onPressed: session.logout, child: Text(t('Выйти', 'Sign out', 'Chiqish'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
