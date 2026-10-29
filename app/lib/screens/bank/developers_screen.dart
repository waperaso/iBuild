import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';
import 'bank_ui.dart';

String _fraction(Map<String, dynamic> fact) => '${fact.i('filed')} / ${fact.i('of')}';

Color _factTone(BuildContext context, Map<String, dynamic> fact, {String done = 'filed'}) {
  final colors = context.colors;
  final total = fact.i('of');
  if (total == 0) return colors.inkMuted;
  return fact.i(done) >= total ? colors.success : colors.warning;
}

String _hours(Tx t, Object? hours) {
  if (hours == null) return '—';
  final value = double.tryParse('$hours') ?? 0;
  if (value >= 24) return '${(value / 24).toStringAsFixed(1)} ${t('дн.', 'd', 'kun')}';
  return '$hours ${t('ч', 'h', 'soat')}';
}

class BankDevelopersScreen extends StatelessWidget {
  const BankDevelopersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/developers',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        return ScreenScroll(
          key: const Key('bank-developers-frame'),
          children: [
            PageTitle(
              title: LocaleScope.copy(context).bankDevelopers,
              subtitle: t('Сводка по фактам, не рейтинг: отчёты, возвраты, скорость ответа',
                  'A summary of facts, not a rating: reports, returns, response time', 'Faktlar yig‘indisi, reyting emas: hisobotlar, qaytarishlar, javob tezligi'),
            ),
            if (items.isEmpty)
              EmptyState(
                title: t('Застройщиков нет', 'No developers', 'Quruvchilar yo‘q'),
                body: t('Здесь появятся застройщики, чьи объекты кредитует банк.', 'Developers whose projects the bank finances will appear here.', 'Bank kreditlaydigan obyektlarning quruvchilari shu yerda ko‘rinadi.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('developers-list'),
                  children: [
                    TableRowBox(header: true, children: [
                      cellText(context, t('Застройщик', 'Developer', 'Quruvchi'), flex: 3, bold: true),
                      cellText(context, t('Объектов', 'Projects', 'Obyektlar'), bold: true),
                      cellText(context, t('Отчёт о продажах', 'Sales report', 'Sotuv hisoboti'), flex: 2, bold: true),
                      cellText(context, t('Возвраты', 'Returns', 'Qaytarishlar'), bold: true),
                      cellText(context, t('Ответ', 'Response', 'Javob'), bold: true),
                    ]),
                    for (final item in items)
                      TableRowBox(
                        key: Key('developer-${item.s('id')}'),
                        onTap: () => context.go('/bank/developers/${item.s('id')}'),
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.s('name'), style: theme.textTheme.titleSmall),
                              Text('${bankAmount(context, item['issued'])} / ${bankAmount(context, item['limit'])} ${bankUnit(context)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                            ]),
                          ),
                          cellText(context, '${item.i('objects')}'),
                          Expanded(
                            flex: 2,
                            child: Row(children: [
                              BankDot(color: _factTone(context, item.obj('salesReport'))),
                              const SizedBox(width: AppSpacing.sm),
                              Text(_fraction(item.obj('salesReport')), style: theme.textTheme.bodyMedium),
                            ]),
                          ),
                          cellText(context, '${item.obj('returns').i('returned')} / ${item.obj('returns').i('total')}'),
                          cellText(context, _hours(t, item['responseHours']), muted: true),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class BankDeveloperScreen extends StatelessWidget {
  const BankDeveloperScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/developers/$id',
      builder: (context, data, reload) => _DeveloperBody(data: data, reload: reload),
    );
  }
}

class _DeveloperBody extends StatelessWidget {
  const _DeveloperBody({required this.data, required this.reload});

  final Map<String, dynamic> data;
  final Future<void> Function() reload;

  Future<void> _file(BuildContext context) async {
    final done = await showPlainDialog<bool>(context: context, builder: (context) => _FilingDialog(data: data));
    if (done == true) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final sales = data.obj('salesReport');
    final quarterly = data.obj('quarterly');
    final supervision = data.obj('supervision');
    final returns = data.obj('returns');
    final reasons = data.list('reasons');
    final recent = data.list('recentReturns');
    final total = returns.i('total');
    return ScreenScroll(
      key: const Key('bank-developer-frame'),
      children: [
        TextButton.icon(
          style: backLinkStyle,
          onPressed: () => context.go('/bank/developers'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(LocaleScope.copy(context).bankDevelopers),
        ),
        const SizedBox(height: AppSpacing.md),
        PageTitle(
          title: data.s('name'),
          subtitle: data.s('contact'),
          trailing: data.b('canFile')
              ? OutlinedButton(key: const Key('file-report'), onPressed: () => _file(context), child: Text(t('Отметить полученный отчёт', 'Record a received report', 'Olingan hisobotni belgilash')))
              : null,
        ),
        KpiRow(children: [
          Kpi(
            label: t('Отчёт о продажах', 'Sales report', 'Sotuv hisoboti'),
            value: _fraction(sales),
            tone: _factTone(context, sales),
            hint: '${t('за', 'for', '')} ${fmtDay(sales['period'])} · ${t('объектов', 'projects', 'obyekt')}',
          ),
          Kpi(
            label: t('Квартальная отчётность', 'Quarterly reporting', 'Choraklik hisobot'),
            value: _fraction(quarterly),
            tone: _factTone(context, quarterly),
            hint: quarterly.s('period'),
          ),
          Kpi(
            label: t('Технадзор, регулярно', 'Supervision, regularly', 'Texnik nazorat, muntazam'),
            value: '${supervision.i('regular')} / ${supervision.i('of')}',
            tone: _factTone(context, supervision, done: 'regular'),
            hint: t('не реже двух актов за 30 дней', 'at least two reports in 30 days', '30 kunda kamida ikkita dalolatnoma'),
          ),
          Kpi(
            label: t('Транши с возвратом', 'Tranches returned', 'Qaytarilgan transhlar'),
            value: total == 0 ? '—' : '${returns.i('returned')} / $total',
            hint: '${t('ответ на запрос банка', 'reply to the bank', 'bank so‘roviga javob')}: ${_hours(t, data['responseHours'])}',
          ),
        ]),
        SectionTitle(t('Объекты', 'Projects', 'Obyektlar')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final object in data.list('objects'))
              TableRowBox(
                onTap: () => context.go('/bank/objects/${object.s('id')}'),
                children: [Expanded(child: Text(object.s('name'), style: theme.textTheme.bodyMedium)), const Icon(Icons.chevron_right, size: 18)],
              ),
          ]),
        ),
        SectionTitle(t('Частые причины возврата', 'Common reasons for returns', 'Qaytarishning ko‘p sabablari')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: reasons.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(t('Возвратов не было.', 'No returns so far.', 'Qaytarishlar bo‘lmagan.'), style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)),
                )
              : Column(children: [
                  for (final reason in reasons)
                    TableRowBox(children: [cellText(context, reason.s('reason'), flex: 4), cellText(context, '× ${reason.i('n')}', align: TextAlign.end, muted: true)]),
                ]),
        ),
        SectionTitle(t('Последние возвраты', 'Latest returns', 'Oxirgi qaytarishlar')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(t('Пока пусто.', 'Nothing yet.', 'Hozircha bo‘sh.'), style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)),
                )
              : Column(children: [
                  for (final row in recent)
                    TableRowBox(children: [
                      SizedBox(width: 100, child: Text(fmtDay(row['at']), style: theme.textTheme.bodySmall)),
                      cellText(context, '${row.s('project')} · ${BankStrings.of(context).trancheNo(row.i('no'))}', flex: 3),
                      cellText(context, row.s('kind') == 'return_all' ? t('целиком', 'in full', 'to‘liq') : '${bankAmount(context, row['returned'])} ${bankUnit(context)}', align: TextAlign.end, muted: true),
                    ]),
                ]),
        ),
      ],
    );
  }
}

class _FilingDialog extends StatefulWidget {
  const _FilingDialog({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_FilingDialog> createState() => _FilingDialogState();
}

class _FilingDialogState extends State<_FilingDialog> {
  String? _project;
  String _kind = 'sales';
  bool _busy = false;

  Future<void> _save() async {
    if (_project == null) return;
    setState(() => _busy = true);
    final api = SessionScope.of(context).api;
    final navigator = Navigator.of(context);
    final period = _kind == 'sales' ? widget.data.s('salesPeriod') : widget.data.obj('quarterly').s('period');
    final ok = await runAction(
      context,
      () => api.postJson('/api/bank/developers/${widget.data.s('id')}/filings', {'projectId': _project, 'kind': _kind, 'period': period}),
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final period = _kind == 'sales' ? widget.data.s('salesPeriod') : widget.data.obj('quarterly').s('period');
    return AlertDialog(
      title: Text(t('Отчёт получен', 'Report received', 'Hisobot olindi')),
      content: SizedBox(
        width: dialogFieldWidth(context),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            key: const Key('filing-project'),
            isExpanded: true,
            initialValue: _project,
            decoration: InputDecoration(labelText: t('Объект', 'Project', 'Obyekt')),
            items: [for (final o in widget.data.list('objects')) DropdownMenuItem(value: o.s('id'), child: Text(o.s('name'), overflow: TextOverflow.ellipsis))],
            onChanged: (value) => setState(() => _project = value),
          ),
          const SizedBox(height: AppSpacing.md),
          FilterChips(
            keyPrefix: 'filing-kind',
            value: _kind,
            onChanged: (value) => setState(() => _kind = value),
            options: [('sales', t('О продажах', 'Sales', 'Sotuv')), ('quarterly', t('Квартальный', 'Quarterly', 'Choraklik'))],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${t('Период', 'Period', 'Davr')}: ${_kind == 'sales' ? fmtDay(period) : period}'),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
        PrimaryButton(key: const Key('filing-save'), label: t('Записать', 'Save', 'Yozish'), busy: _busy, onPressed: _project == null ? null : _save),
      ],
    );
  }
}
