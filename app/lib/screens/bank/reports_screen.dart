import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../download.dart';
import '../../l10n.dart';
import '../../money.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';

const _groups = ['money', 'time', 'control', 'audit'];

String reportGroupName(Tx t, String group) {
  return switch (group) {
    'money' => t('Деньги', 'Money', 'Pul'),
    'time' => t('Время', 'Time', 'Vaqt'),
    'control' => t('Контроль', 'Control', 'Nazorat'),
    _ => t('Аудит', 'Audit', 'Audit'),
  };
}

/// Title and the line under it, by the code of the report.
(String, String) reportNames(Tx t, String code, String fallbackTitle, String fallbackSubtitle) {
  return switch (code) {
    'portfolio_summary' => (
        t('Сводка по портфелю', 'Portfolio summary', 'Portfel yig‘indisi'),
        t('Лимит, выдано, остаток по каждому объекту', 'Limit, paid and left for each project', 'Har bir obyekt bo‘yicha limit, to‘langan va qoldiq')
      ),
    'over_confirmed' => (
        t('Выдано сверх подтверждённого', 'Paid above the confirmed', 'Tasdiqlangandan ortiq to‘langan'),
        t('Где выплат больше, чем подтвердили осмотры', 'Where payouts exceed what inspections confirmed', 'To‘lovlar ko‘rik tasdiqlaganidan ko‘p joylar')
      ),
    'limit_expiry' => (
        t('Остаток лимита и срок освоения', 'Limit left and drawdown term', 'Limit qoldig‘i va o‘zlashtirish muddati'),
        t('Кредиты, у которых заканчивается срок выдач', 'Credits whose drawdown period is ending', 'To‘lov muddati tugayotgan kreditlar')
      ),
    'stage_time' => (
        t('Время транша по этапам', 'Tranche time by step', 'Transh vaqti bosqichlar bo‘yicha'),
        t('Сколько дней заявка проводит на каждом шаге', 'How many days a request spends at each step', 'Ariza har bir bosqichda necha kun turadi')
      ),
    'overdue_stages' => (
        t('Просроченные этапы', 'Overdue steps', 'Muddati o‘tgan bosqichlar'),
        t('Кто и на каком этапе превысил срок банка', 'Who went past the bank term, and at which step', 'Kim va qaysi bosqichda bank muddatidan oshdi')
      ),
    'forecast' => (
        t('Прогноз сдачи против срока кредита', 'Completion forecast against the credit term', 'Topshirish prognozi va kredit muddati'),
        t('Объекты, у которых сдача уходит', 'Projects that are running late', 'Topshirishi kechikayotgan obyektlar')
      ),
    'returns' => (
        t('Возвраты заявок и причины', 'Returned requests and reasons', 'Qaytarilgan arizalar va sabablar'),
        t('Что чаще всего возвращают застройщикам', 'What is returned to developers most often', 'Quruvchilarga ko‘proq nima qaytariladi')
      ),
    'discipline' => (
        t('Дисциплина застройщиков', 'Developer discipline', 'Quruvchilar intizomi'),
        t('Отчёты о продажах, квартальная отчётность', 'Sales reports, quarterly reporting', 'Sotuv hisobotlari, choraklik hisobot')
      ),
    'inspections' => (
        t('Осмотры и замеры', 'Inspections and measurements', 'Ko‘riklar va o‘lchovlar'),
        t('Выполнено, просрочено, по экспертам', 'Done, overdue, by expert', 'Bajarilgan, muddati o‘tgan, ekspertlar bo‘yicha')
      ),
    'decision_journal' => (
        t('Журнал решений', 'Journal of decisions', 'Qarorlar jurnali'),
        t('Кто, когда и на каком основании выдал транш', 'Who paid a tranche, when and on what ground', 'Transhni kim, qachon va qanday asosda to‘lagan')
      ),
    'waived' => (
        t('Принято с обоснованием', 'Accepted with a reason', 'Asos bilan qabul qilingan'),
        t('Все исключения: причина, комментарий, кто принял', 'All exceptions: reason, comment, who accepted', 'Barcha istisnolar: sabab, izoh, kim qabul qilgan')
      ),
    _ => (fallbackTitle, fallbackSubtitle),
  };
}

class BankReportsScreen extends StatelessWidget {
  const BankReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/reports',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final catalog = data.list('catalog');
        final schedules = {for (final s in data.list('schedules')) s.s('code'): s};
        return ScreenScroll(
          key: const Key('bank-reports-frame'),
          children: [
            PageTitle(
              title: LocaleScope.copy(context).bankReports,
              subtitle: t('Откройте отчёт, выберите период и скачайте в Excel или PDF',
                  'Open a report, pick a period and download it as Excel or PDF', 'Hisobotni oching, davrni tanlang va Excel yoki PDF sifatida yuklab oling'),
            ),
            for (final group in _groups) ...[
              SectionTitle(reportGroupName(t, group)),
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final item in catalog.where((c) => c.s('group') == group))
                      Builder(builder: (context) {
                        final names = reportNames(t, item.s('code'), item.s('title'), item.s('subtitle'));
                        final scheduled = schedules[item.s('code')]?.b('enabled') == true;
                        return TableRowBox(
                          key: Key('report-${item.s('code')}'),
                          onTap: () => context.go('/bank/reports/${item.s('code')}'),
                          children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(names.$1, style: theme.textTheme.titleSmall),
                                Text(names.$2, style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                              ]),
                            ),
                            if (scheduled) Tag(label: t('По расписанию', 'Scheduled', 'Jadval bo‘yicha'), color: colors.success),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class BankReportScreen extends StatelessWidget {
  const BankReportScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/reports',
      builder: (context, meta, reload) => _ReportView(code: code, meta: meta),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView({required this.code, required this.meta});

  final String code;
  final Map<String, dynamic> meta;

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  late String _from;
  late String _to;
  String _branch = '';
  String _project = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    _from = '${now.year}-${two(now.month)}-01';
    final last = DateTime(now.year, now.month + 1, 0);
    _to = '${last.year}-${two(last.month)}-${two(last.day)}';
  }

  String get _query {
    final params = ['from=$_from', 'to=$_to', if (_branch.isNotEmpty) 'branch=${Uri.encodeQueryComponent(_branch)}', if (_project.isNotEmpty) 'project=$_project'];
    return params.join('&');
  }

  Future<void> _pick(bool start) async {
    final day = await pickDay(context, initial: start ? _from : _to);
    if (day == null) return;
    setState(() {
      if (start) {
        _from = day;
        if (_to.compareTo(_from) < 0) _to = _from;
      } else {
        _to = day;
        if (_to.compareTo(_from) < 0) _from = _to;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final catalog = widget.meta.list('catalog').where((c) => c.s('code') == widget.code).toList();
    final names = reportNames(t, widget.code, catalog.isEmpty ? widget.code : catalog.first.s('title'), catalog.isEmpty ? '' : catalog.first.s('subtitle'));
    final branches = (widget.meta['branches'] as List? ?? const []).map((b) => '$b').toList();
    final objects = widget.meta.list('objects');
    return JsonLoader(
      path: '/api/bank/reports/${widget.code}?$_query',
      builder: (context, data, reload) {
        final theme = Theme.of(context);
        final colors = context.colors;
        final columns = data.list('columns');
        final rows = data.list('rows');
        final summary = data.list('summary');
        final copy = LocaleScope.copy(context);
        return ScreenScroll(
          key: const Key('bank-report-frame'),
          children: [
            TextButton.icon(
              key: const Key('back-to-reports'),
              style: backLinkStyle,
              onPressed: () => context.go('/bank/reports'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(LocaleScope.copy(context).bankReports),
            ),
            const SizedBox(height: AppSpacing.md),
            PageTitle(
              title: names.$1,
              subtitle: names.$2,
              trailing: Wrap(spacing: AppSpacing.sm, children: [
                for (final format in const ['xlsx', 'pdf', 'csv'])
                  OutlinedButton.icon(
                    key: Key('export-$format'),
                    onPressed: () => openBankFile('/api/bank/reports/${widget.code}/file?$_query&format=$format'),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(format.toUpperCase()),
                  ),
              ]),
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(key: const Key('report-from'), onPressed: () => _pick(true), icon: const Icon(Icons.event_outlined, size: 18), label: Text('${t('с', 'from', 'dan')} ${fmtDay(_from)}')),
                OutlinedButton.icon(key: const Key('report-to'), onPressed: () => _pick(false), icon: const Icon(Icons.event_outlined, size: 18), label: Text('${t('по', 'to', 'gacha')} ${fmtDay(_to)}')),
                if (branches.isNotEmpty)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: const Key('report-branch'),
                      isExpanded: true,
                      initialValue: _branch,
                      decoration: InputDecoration(labelText: t('Филиал', 'Branch', 'Filial'), isDense: true),
                      items: [DropdownMenuItem(value: '', child: Text(t('Все', 'All', 'Hammasi'))), for (final b in branches) DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))],
                      onChanged: (value) => setState(() => _branch = value ?? ''),
                    ),
                  ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    key: const Key('report-project'),
                    isExpanded: true,
                    initialValue: _project,
                    decoration: InputDecoration(labelText: t('Объект', 'Project', 'Obyekt'), isDense: true),
                    items: [DropdownMenuItem(value: '', child: Text(t('Все', 'All', 'Hammasi'))), for (final o in objects) DropdownMenuItem(value: o.s('id'), child: Text(o.s('name'), overflow: TextOverflow.ellipsis))],
                    onChanged: (value) => setState(() => _project = value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (summary.isNotEmpty)
              KpiRow(children: [
                for (final item in summary)
                  Kpi(
                    label: copy.known(item.s('label')),
                    value: item.s('value'),
                    tone: item.s('tone') == 'bad' ? colors.danger : null,
                  ),
              ]),
            const SizedBox(height: AppSpacing.lg),
            if (rows.isEmpty)
              EmptyState(
                title: t('За период ничего нет', 'Nothing for this period', 'Bu davrda hech narsa yo‘q'),
                body: t('Измените период или фильтры.', 'Change the period or the filters.', 'Davr yoki filtrlarni o‘zgartiring.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: (MediaQuery.sizeOf(context).width - 120).clamp(320, 2000)),
                    child: DataTable(
                      key: const Key('report-table'),
                      headingTextStyle: theme.textTheme.titleSmall,
                      columns: [
                        for (final column in columns)
                          DataColumn(label: Text(copy.known(column.s('label'))), numeric: column.s('kind') == 'money' || column.s('kind') == 'int' || column.s('kind') == 'percent'),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(cells: [for (final column in columns) DataCell(Text(_cell(copy, column, row[column.s('key')])))]),
                      ],
                    ),
                  ),
                ),
              ),
            if (data.s('note').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(copy.known(data.s('note')), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
              ),
            const SizedBox(height: AppSpacing.xl),
            _ScheduleCard(code: widget.code, schedule: data.obj('schedule'), canSchedule: widget.meta.b('canSchedule')),
          ],
        );
      },
    );
  }

  String _cell(AppCopy copy, Map<String, dynamic> column, Object? value) {
    if (value == null) return '';
    return switch (column.s('kind')) {
      'money' => moneyMillions(value),
      'percent' => '$value%',
      'date' => fmtDay(value),
      _ => copy.known('$value'),
    };
  }
}

/// Weekly delivery by mail. The recipients are kept; sending needs a mail
/// server, which is not connected, and the card says so.
class _ScheduleCard extends StatefulWidget {
  const _ScheduleCard({required this.code, required this.schedule, required this.canSchedule});

  final String code;
  final Map<String, dynamic> schedule;
  final bool canSchedule;

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  late bool _enabled = widget.schedule.b('enabled');
  late final _recipients = TextEditingController(text: widget.schedule.s('recipients'));
  bool _busy = false;
  bool _saved = false;

  @override
  void dispose() {
    _recipients.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _saved = false;
    });
    final api = SessionScope.of(context).api;
    final ok = await runAction(
      context,
      () => api.postJson('/api/bank/reports/${widget.code}/schedule', {'enabled': _enabled, 'recipients': _recipients.text.trim()}),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = ok;
    });
  }

  Future<void> _sendNow() async {
    final t = Tx.of(context);
    final api = SessionScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    var mail = '';
    final ok = await runAction(context, () async {
      final answer = await api.postJson('/api/bank/reports/${widget.code}/send', {});
      mail = answer.s('mail');
    });
    if (!ok) return;
    messenger.showSnackBar(SnackBar(content: Text(mailResultText(t, mail, t('Отчёт', 'The report', 'Hisobot')))));
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return IBuildCard(
      child: Column(
        key: const Key('report-schedule'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('Расписание', 'Schedule', 'Jadval'), style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const Key('schedule-switch'),
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: widget.canSchedule ? (value) => setState(() => _enabled = value) : null,
            title: Text(t('Отправлять каждый понедельник', 'Send every Monday', 'Har dushanba yuborish')),
          ),
          TextField(
            key: const Key('schedule-recipients'),
            controller: _recipients,
            enabled: widget.canSchedule,
            decoration: InputDecoration(labelText: t('Получатели (через запятую)', 'Recipients (comma separated)', 'Qabul qiluvchilar (vergul bilan)')),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t('По понедельникам с 9:00 получатели получают отчёт за прошлую неделю файлом Excel. Если почта ещё не подключена, письма ждут в очереди у администратора платформы.',
                'On Mondays from 9:00 the recipients get last week’s report as an Excel file. If mail is not connected yet, letters wait in the platform admin’s queue.',
                'Dushanba kunlari 9:00 dan qabul qiluvchilar o‘tgan hafta hisobotini Excel fayl sifatida oladi. Pochta ulanmagan bo‘lsa, xatlar platforma administratori navbatida kutadi.'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
          ),
          if (widget.canSchedule) ...[
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              PrimaryButton(key: const Key('schedule-save'), label: t('Сохранить', 'Save', 'Saqlash'), busy: _busy, onPressed: _save),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(key: const Key('schedule-send'), onPressed: _busy ? null : _sendNow, child: Text(t('Отправить сейчас', 'Send now', 'Hozir yuborish'))),
              if (_saved) Padding(padding: const EdgeInsets.only(left: AppSpacing.md), child: Text(t('Сохранено', 'Saved', 'Saqlandi'), key: const Key('schedule-saved'))),
            ]),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(t('Расписание меняют руководитель, риск-менеджер и администратор.', 'The schedule is changed by a head, a risk manager or an administrator.', 'Jadvalni rahbar, risk-menejer va administrator o‘zgartiradi.'), style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
