import 'package:flutter/material.dart';

import '../api.dart';
import '../l10n.dart';
import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';

/// Text in the language of the person: `tx(context)('ru', 'en', 'uz')`.
class Tx {
  const Tx(this.language);

  factory Tx.of(BuildContext context) => Tx(LocaleScope.copy(context).language);

  final AppLanguage language;

  String call(String ru, String en, String uz) {
    return switch (language) {
      AppLanguage.en => en,
      AppLanguage.uz => uz,
      AppLanguage.ru => ru,
    };
  }
}

/// Reading a JSON answer without a model class for each screen.
extension JsonRead on Map<String, dynamic> {
  String s(String key) => this[key] == null ? '' : '${this[key]}';

  int i(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  double d(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

  bool b(String key) => this[key] == true;

  List<Map<String, dynamic>> list(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) item.map((k, v) => MapEntry(k.toString(), v)),
    ];
  }

  Map<String, dynamic> obj(String key) {
    final value = this[key];
    if (value is! Map) return <String, dynamic>{};
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
}

/// 2026-10-29 -> 29.10.2026. Anything else is returned as it came.
String fmtDay(Object? value) {
  final text = '${value ?? ''}';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return text;
  return '${match.group(3)}.${match.group(2)}.${match.group(1)}';
}

String fmtTime(Object? value) {
  final parsed = DateTime.tryParse('${value ?? ''}');
  if (parsed == null) return '${value ?? ''}';
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String errorText(BuildContext context, Object error) {
  if (error is ApiException) return LocaleScope.copy(context).known(error.message);
  return Tx.of(context)('Что-то пошло не так. Попробуйте ещё раз.', 'Something went wrong. Please try again.',
      'Nimadir noto‘g‘ri ketdi. Qayta urinib ko‘ring.');
}

/// Loads one JSON path, shows a spinner or an error with a retry, and keeps the
/// old picture on screen while it reloads.
class JsonLoader extends StatefulWidget {
  const JsonLoader({super.key, required this.path, required this.builder});

  final String path;
  final Widget Function(BuildContext context, Map<String, dynamic> data, Future<void> Function() reload) builder;

  @override
  State<JsonLoader> createState() => _JsonLoaderState();
}

class _JsonLoaderState extends State<JsonLoader> {
  Map<String, dynamic>? _data;
  String? _error;
  int _generation = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void didUpdateWidget(JsonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final api = SessionScope.of(context).api;
    try {
      final data = await api.getJson(widget.path);
      if (!mounted || generation != _generation) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } on ApiException catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) return widget.builder(context, data, _load);
    final error = _error;
    if (error != null) {
      final t = Tx.of(context);
      return ScreenScroll(
        children: [
          ErrorNote(message: error),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const Key('reload'),
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: Text(t('Повторить', 'Try again', 'Qayta urinish')),
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted)),
                ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

/// One number with its label.
class Kpi extends StatelessWidget {
  const Kpi({super.key, required this.label, required this.value, this.hint, this.tone});

  final String label;
  final String value;
  final String? hint;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: tone)),
          if (hint != null && hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
            ),
        ],
      ),
    );
  }
}

/// KPI cards that wrap to two columns on a narrow screen.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? children.length.clamp(1, 4) : 2;
        final width = (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.value, required this.onChanged, this.keyPrefix = 'chip'});

  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          ChoiceChip(
            key: Key('$keyPrefix-${option.$1}'),
            label: Text(option.$2),
            selected: option.$1 == value,
            onSelected: (_) => onChanged(option.$1),
          ),
      ],
    );
  }
}

/// A row of a plain table: cells separated, a divider below.
class TableRowBox extends StatelessWidget {
  const TableRowBox({super.key, required this.children, this.onTap, this.header = false});

  final List<Widget> children;
  final VoidCallback? onTap;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: children),
          ),
        ),
        Divider(height: 1, color: header ? colors.ink.withValues(alpha: 0.2) : colors.outline),
      ],
    );
  }
}

Widget cellText(BuildContext context, String text, {int flex = 1, bool muted = false, bool bold = false, TextAlign? align}) {
  final theme = Theme.of(context);
  return Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Text(
        text,
        textAlign: align,
        style: (bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
            ?.copyWith(color: muted ? context.colors.inkMuted : null),
      ),
    ),
  );
}

/// A coloured label: a level, a status.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// A day picked from a calendar, shown as dd.MM.yyyy and kept as yyyy-MM-dd.
Future<String?> pickDay(BuildContext context, {String? initial, DateTime? first, DateTime? last}) async {
  final start = DateTime.tryParse(initial ?? '') ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: first ?? DateTime(2024),
    lastDate: last ?? DateTime(2035),
  );
  if (picked == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${picked.year}-${two(picked.month)}-${two(picked.day)}';
}

/// Asks, does, and shows the error in a snack when it fails.
Future<bool> runAction(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = Tx.of(context);
  final copy = LocaleScope.copy(context);
  try {
    await action();
    return true;
  } on ApiException catch (failure) {
    messenger.showSnackBar(SnackBar(content: Text(copy.known(failure.message))));
    return false;
  } catch (_) {
    messenger.showSnackBar(SnackBar(
      content: Text(message('Что-то пошло не так. Попробуйте ещё раз.', 'Something went wrong. Please try again.',
          'Nimadir noto‘g‘ri ketdi. Qayta urinib ko‘ring.')),
    ));
    return false;
  }
}

/// What happened to a letter, in a phrase for a snackbar.
String mailResultText(Tx t, String status, String what) {
  switch (status) {
    case 'sent':
      return t('$what отправлено по почте и записано в журнал.', '$what emailed and written to the journal.', '$what pochta orqali yuborildi va jurnalga yozildi.');
    case 'failed':
      return t('$what записано в журнал, но письмо не ушло. Администратор увидит ошибку в разделе «Почта».', '$what is in the journal, but the email failed. The admin sees the error under “Mail”.', '$what jurnalga yozildi, lekin xat yuborilmadi. Administrator xatoni “Pochta” bo‘limida ko‘radi.');
    case 'no_recipient':
      return t('$what записано в журнал. У застройщика нет адреса почты для письма.', '$what is in the journal. The developer has no email address on file.', '$what jurnalga yozildi. Quruvchining pochta manzili yo‘q.');
    default:
      return t('$what записано в журнал. Письмо ждёт в очереди: почта ещё не подключена.', '$what is in the journal. The email waits in the queue: mail is not connected yet.', '$what jurnalga yozildi. Xat navbatda: pochta hali ulanmagan.');
  }
}
