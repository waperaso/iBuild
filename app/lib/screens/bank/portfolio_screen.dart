import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';
import 'bank_ui.dart';

const _stageCodes = ['docs', 'inspection', 'specialist', 'approval', 'payout'];

String bankStageName(Tx t, String code) {
  return switch (code) {
    'docs' => t('Документы', 'Documents', 'Hujjatlar'),
    'inspection' => t('Осмотр', 'Inspection', 'Ko‘rik'),
    'specialist' => t('Специалист', 'Specialist', 'Mutaxassis'),
    'approval' => t('Согласование', 'Approval', 'Kelishuv'),
    'payout' => t('Выплата', 'Payout', 'To‘lov'),
    _ => code,
  };
}

/// A signal of the portfolio in the language of the person. The server sends the
/// code and the numbers; the sentence is built here.
String bankSignalTitle(Tx t, Map<String, dynamic> signal) {
  final p = signal.obj('params');
  return switch (signal.s('code')) {
    'paused' => t('Финансирование приостановлено', 'Financing is suspended', 'Moliyalashtirish to‘xtatilgan'),
    'over_confirmed' => t(
        'Выдано на ${p.s('amount')} млн больше, чем подтверждено осмотрами',
        'Paid ${p.s('amount')} m more than the inspections confirmed',
        'Ko‘riklar tasdiqlaganidan ${p.s('amount')} mln ko‘p to‘langan'),
    'facility_ended' => t('Срок освоения кредита закончился ${fmtDay(p['date'])}',
        'The credit drawdown period ended on ${fmtDay(p['date'])}', 'Kreditni o‘zlashtirish muddati ${fmtDay(p['date'])} da tugadi'),
    'facility_ending' => t('Срок освоения кредита заканчивается ${fmtDay(p['date'])}',
        'The credit drawdown period ends on ${fmtDay(p['date'])}', 'Kreditni o‘zlashtirish muddati ${fmtDay(p['date'])} da tugaydi'),
    'forecast_late' => t('Прогноз сдачи позже срока на ${p.i('days')} дн.', 'Forecast is ${p.i('days')} days past the term',
        'Topshirish prognozi muddatdan ${p.i('days')} kun keyin'),
    'sales_report' => t('Не сдан отчёт о продажах за ${fmtDay(p['date'])}', 'The sales report for ${fmtDay(p['date'])} is missing',
        '${fmtDay(p['date'])} uchun sotuv hisoboti topshirilmagan'),
    'inspection_overdue' => t('Просрочен осмотр от ${fmtDay(p['date'])}', 'The inspection of ${fmtDay(p['date'])} is overdue',
        '${fmtDay(p['date'])} dagi ko‘rik muddati o‘tgan'),
    _ => signal.s('title'),
  };
}

String bankSignalAction(Tx t, String action) {
  return switch (action) {
    'stop_lines' => t('Остановить выдачу по статьям', 'Stop payouts on these items', 'Moddalar bo‘yicha to‘lovni to‘xtatish'),
    'request_schedule' => t('Запросить обновлённый график', 'Ask for an updated schedule', 'Yangilangan jadvalni so‘rash'),
    'remind' => t('Напомнить застройщику', 'Remind the developer', 'Quruvchiga eslatish'),
    'schedule_inspection' => t('Назначить осмотр', 'Plan an inspection', 'Ko‘rik tayinlash'),
    _ => t('Открыть объект', 'Open the project', 'Obyektni ochish'),
  };
}

String bankLevelName(Tx t, String level) {
  return switch (level) {
    'block' => t('Блок', 'Block', 'Blok'),
    'warning' => t('Внимание', 'Warning', 'Diqqat'),
    _ => t('Напоминание', 'Reminder', 'Eslatma'),
  };
}

/// The attention list: one row per signal, with the ground in the contract and the next step.
class BankSignalRow extends StatelessWidget {
  const BankSignalRow({super.key, required this.signal, this.showObject = true, this.onDone});

  final Map<String, dynamic> signal;
  final bool showObject;
  final VoidCallback? onDone;

  Future<void> _act(BuildContext context) async {
    final action = signal.s('action');
    final id = signal.s('projectId');
    final api = SessionScope.of(context).api;
    final t = Tx.of(context);
    switch (action) {
      case 'remind':
        var mail = '';
        final done = await runAction(context, () async {
          final answer = await api.postJson('/api/bank/objects/$id/remind', {'kind': 'sales_report'});
          mail = answer.s('mail');
        });
        if (done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mailResultText(t, mail, 'Напоминание'))));
          onDone?.call();
        }
      case 'schedule_inspection':
        context.go('/bank/inspections');
      case 'request_schedule':
        var mail = '';
        final done = await runAction(context, () async {
          final answer = await api.postJson('/api/bank/objects/$id/remind', {'kind': 'schedule'});
          mail = answer.s('mail');
        });
        if (done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mailResultText(t, mail, 'Запрос графика'))));
          onDone?.call();
        }
      default:
        context.go('/bank/objects/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final color = bankLevelColor(context, signal.s('level'));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 5, right: AppSpacing.md), child: BankDot(color: color)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showObject)
                  InkWell(
                    onTap: () => context.go('/bank/objects/${signal.s('projectId')}'),
                    child: Text(signal.s('projectName'), style: theme.textTheme.titleSmall),
                  ),
                Text(bankSignalTitle(t, signal), style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${t('Основание', 'Basis', 'Asos')}: ${signal.s('basis')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            key: Key('signal-${signal.s('projectId')}-${signal.s('code')}'),
            onPressed: () => _act(context),
            child: Text(bankSignalAction(t, signal.s('action'))),
          ),
        ],
      ),
    );
  }
}

class BankPortfolioScreen extends StatelessWidget {
  const BankPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/portfolio',
      builder: (context, data, reload) => _PortfolioBody(data: data, reload: reload),
    );
  }
}

class _PortfolioBody extends StatelessWidget {
  const _PortfolioBody({required this.data, required this.reload});

  final Map<String, dynamic> data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final kpi = data.obj('kpi');
    final signals = data.list('signals');
    final stages = data.list('stageDays');
    final deadlines = data.list('deadlines');
    final unit = bankUnit(context);
    final average = kpi['averageDays'];
    final maxDays = stages.fold<double>(0.1, (m, s) => s.d('days') > m ? s.d('days') : m);
    return ScreenScroll(
      key: const Key('bank-portfolio-frame'),
      children: [
        PageTitle(
          title: LocaleScope.copy(context).bankPortfolio,
          subtitle: '${data.s('bankName')} · ${t('суммы в', 'amounts in', 'summalar:')} $unit',
        ),
        KpiRow(children: [
          Kpi(label: t('Объектов в портфеле', 'Projects in the portfolio', 'Portfeldagi obyektlar'), value: '${kpi.i('objects')}'),
          Kpi(
            label: t('Выдано из лимита', 'Paid out of the limit', 'Limitdan to‘langan'),
            value: bankAmount(context, data['issued']),
            hint: '${t('из', 'of', 'dan')} ${bankAmount(context, data['limit'])} $unit',
          ),
          Kpi(
            key: const Key('kpi-attention'),
            label: t('Требуют внимания', 'Need attention', 'E’tibor talab qiladi'),
            value: '${kpi.i('attention')}',
            tone: kpi.i('attention') > 0 ? colors.warning : null,
            hint: '${t('траншей в работе', 'tranches in progress', 'ishdagi transhlar')}: ${kpi.i('tranchesInWork')}',
          ),
          Kpi(
            label: t('Средний срок транша', 'Average tranche time', 'O‘rtacha transh muddati'),
            value: average == null ? '—' : '$average ${t('дн.', 'd', 'kun')}',
            hint: t('рабочих дней, этот квартал', 'working days, this quarter', 'ish kunlari, shu chorak'),
          ),
        ]),
        SectionTitle(t('Что требует внимания', 'What needs attention', 'Nima e’tibor talab qiladi')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: signals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    t('Всё в порядке: замечаний по объектам нет.', 'All is in order: no findings at the projects.',
                        'Hammasi joyida: obyektlar bo‘yicha izohlar yo‘q.'),
                    key: const Key('portfolio-no-signals'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    for (final signal in signals) ...[
                      BankSignalRow(signal: signal, onDone: reload),
                      Divider(height: 1, color: colors.outline),
                    ],
                    if (data.i('moreObjects') > 0)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          t('Остальные ${data.i('moreObjects')} объектов без замечаний.',
                              'The other ${data.i('moreObjects')} projects have no findings.',
                              'Qolgan ${data.i('moreObjects')} ta obyektda izoh yo‘q.'),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                        ),
                      ),
                  ],
                ),
        ),
        SectionTitle(t('Сколько дней транш проводит на этапе', 'Days a tranche spends at each step', 'Transh bosqichda necha kun turadi')),
        IBuildCard(
          child: Column(
            key: const Key('portfolio-stage-days'),
            children: [
              for (final code in _stageCodes)
                Builder(builder: (context) {
                  final item = stages.firstWhere((s) => s.s('code') == code, orElse: () => {'days': 0});
                  final days = item.d('days');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(width: 130, child: Text(bankStageName(t, code), style: theme.textTheme.bodyMedium)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: days / maxDays,
                              minHeight: 10,
                              backgroundColor: colors.surfaceAlt,
                              color: bankBlue(context),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text('$days ${t('дн.', 'd', 'kun')}', textAlign: TextAlign.end, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }),
              if (average == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t('Данных пока мало: считаем по закрытым этапам этого квартала.',
                        'Not enough data yet: counted from the steps closed this quarter.',
                        'Ma’lumot hali kam: shu chorakda yopilgan bosqichlar bo‘yicha hisoblanadi.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                ),
            ],
          ),
        ),
        SectionTitle(t('Ближайшие сроки', 'Nearest deadlines', 'Yaqin muddatlar')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: deadlines.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(t('Ближайших сроков нет.', 'No deadlines ahead.', 'Yaqin muddatlar yo‘q.'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)),
                )
              : Column(
                  key: const Key('portfolio-deadlines'),
                  children: [
                    for (final item in deadlines)
                      TableRowBox(children: [
                        SizedBox(width: 100, child: Text(fmtDay(item['day']), style: theme.textTheme.titleSmall)),
                        Expanded(child: Text(_deadlineTitle(t, item), style: theme.textTheme.bodyMedium)),
                        Text('${item['note'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                      ]),
                  ],
                ),
        ),
      ],
    );
  }
}

String _deadlineTitle(Tx t, Map<String, dynamic> item) {
  final title = item.s('title');
  return switch (item.s('kind')) {
    'inspection' => t(title, title.replaceFirst('Осмотр ', 'Inspection: '), title.replaceFirst('Осмотр ', 'Ko‘rik: ')),
    'sales_report' => t(
        title,
        title.replaceFirstMapped(RegExp(r'по (\d+) объектам'), (m) => 'for ${m[1]} projects').replaceFirst('Отчёты о продажах', 'Sales reports'),
        title.replaceFirstMapped(RegExp(r'по (\d+) объектам'), (m) => '${m[1]} ta obyekt bo‘yicha').replaceFirst('Отчёты о продажах', 'Sotuv hisobotlari')),
    'quarterly' => t(title, 'Quarterly reports of developers', 'Quruvchilarning choraklik hisobotlari'),
    'facility' => t(title, title.replaceFirst('Конец срока освоения кредита,', 'End of the credit drawdown period,'),
        title.replaceFirst('Конец срока освоения кредита,', 'Kreditni o‘zlashtirish muddati tugashi,')),
    _ => title,
  };
}
