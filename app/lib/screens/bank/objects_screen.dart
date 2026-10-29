import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';
import 'bank_ui.dart';
import 'portfolio_screen.dart';

class BankObjectsScreen extends StatefulWidget {
  const BankObjectsScreen({super.key});

  @override
  State<BankObjectsScreen> createState() => _BankObjectsScreenState();
}

class _BankObjectsScreenState extends State<BankObjectsScreen> {
  String _filter = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/objects',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final all = data.list('items');
        final items = [
          for (final item in all)
            if ((_filter == 'all' ||
                    (_filter == 'attention' && item.i('signalCount') > 0) ||
                    (_filter == 'paused' && item.b('paused'))) &&
                (_query.isEmpty ||
                    '${item.s('name')} ${item.s('developer')} ${item.s('address')}'.toLowerCase().contains(_query.toLowerCase())))
              item,
        ];
        return ScreenScroll(
          key: const Key('bank-objects-frame'),
          children: [
            PageTitle(
              title: LocaleScope.copy(context).projects,
              subtitle: t('Личное дело каждой стройки', 'The personal file of each construction site', 'Har bir qurilishning shaxsiy ishi'),
            ),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChips(
                  keyPrefix: 'objects-filter',
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                  options: [
                    ('all', t('Все', 'All', 'Hammasi')),
                    ('attention', t('С замечаниями', 'With findings', 'Izohli')),
                    ('paused', t('Приостановлены', 'Suspended', 'To‘xtatilgan')),
                  ],
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    key: const Key('objects-search'),
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: t('Поиск по объекту или застройщику', 'Search by project or developer', 'Obyekt yoki quruvchi bo‘yicha qidirish'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(
                title: t('Объектов не найдено', 'No projects found', 'Obyektlar topilmadi'),
                body: t('Измените фильтр или поиск.', 'Change the filter or the search.', 'Filtr yoki qidiruvni o‘zgartiring.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('objects-list'),
                  children: [
                    for (final item in items)
                      TableRowBox(
                        key: Key('object-${item.s('id')}'),
                        onTap: () => context.go('/bank/objects/${item.s('id')}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: BankDot(color: bankLevelColor(context, item.s('level'))),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.s('name'), style: theme.textTheme.titleSmall),
                                Text(item.s('developer'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                              ],
                            ),
                          ),
                          cellText(context, '${bankAmount(context, item['issued'])} / ${bankAmount(context, item['credit_limit'])}', flex: 2),
                          cellText(context, item.s('until').isEmpty ? '—' : fmtDay(item['until']), flex: 1, muted: true),
                          if (item.b('paused'))
                            Tag(label: t('Приостановлен', 'Suspended', 'To‘xtatilgan'), color: colors.danger)
                          else if (item.i('signalCount') > 0)
                            Tag(label: '${item.i('signalCount')}', color: colors.warning),
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

class BankObjectScreen extends StatelessWidget {
  const BankObjectScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/objects/$id',
      builder: (context, data, reload) => _ObjectBody(data: data, reload: reload),
    );
  }
}

class _ObjectBody extends StatelessWidget {
  const _ObjectBody({required this.data, required this.reload});

  final Map<String, dynamic> data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final object = data.obj('object');
    final signals = data.list('signals');
    final unit = bankUnit(context);
    final until = object.s('until');
    return ScreenScroll(
      key: const Key('bank-object-frame'),
      children: [
        TextButton.icon(
          key: const Key('back-to-objects'),
          style: backLinkStyle,
          onPressed: () => context.go('/bank/objects'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(LocaleScope.copy(context).projects),
        ),
        const SizedBox(height: AppSpacing.md),
        PageTitle(
          title: object.s('name'),
          subtitle: '${object.s('address')} · ${object.s('developer')}',
          trailing: object.b('paused') ? Tag(label: t('Финансирование приостановлено', 'Financing suspended', 'Moliyalashtirish to‘xtatilgan'), color: colors.danger) : null,
        ),
        KpiRow(children: [
          Kpi(label: t('Лимит кредита', 'Credit limit', 'Kredit limiti'), value: bankAmount(context, object['credit_limit']), hint: unit),
          Kpi(label: t('Выдано', 'Paid out', 'To‘langan'), value: bankAmount(context, object['issued']), hint: unit),
          Kpi(label: t('Остаток лимита', 'Limit left', 'Limit qoldig‘i'), value: bankAmount(context, object['left']), hint: unit),
          Kpi(label: t('Срок освоения', 'Drawdown until', 'O‘zlashtirish muddati'), value: until.isEmpty ? '—' : fmtDay(until)),
        ]),
        SectionTitle(t('Что требует внимания', 'What needs attention', 'Nima e’tibor talab qiladi')),
        IBuildCard(
          padding: EdgeInsets.zero,
          child: signals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(t('Замечаний нет.', 'No findings.', 'Izohlar yo‘q.'), style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)),
                )
              : Column(children: [
                  for (final signal in signals) ...[
                    BankSignalRow(signal: signal, showObject: false, onDone: reload),
                    Divider(height: 1, color: colors.outline),
                  ],
                ]),
        ),
        SectionTitle(t('Бюджет и факт', 'Budget and actuals', 'Byudjet va fakt')),
        _budget(context, t),
        SectionTitle(t('Транши', 'Tranches', 'Transhlar')),
        _tranches(context, t),
        SectionTitle(t('Осмотры', 'Inspections', 'Ko‘riklar')),
        _inspections(context, t),
        SectionTitle(t('Документы объекта', 'Project documents', 'Obyekt hujjatlari')),
        _documents(context, t),
        SectionTitle(t('Отчётность застройщика', 'Developer reports', 'Quruvchi hisobotlari')),
        _filings(context, t),
      ],
    );
  }

  Widget _budget(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final rows = data.list('budget');
    if (rows.isEmpty) {
      return EmptyState(
        title: t('Смета ещё не загружена', 'The budget is not loaded yet', 'Smeta hali yuklanmagan'),
        body: t('Застройщик не загрузил статьи расходов.', 'The developer has not loaded the cost items.', 'Quruvchi xarajat moddalarini yuklamagan.'),
      );
    }
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(
        key: const Key('object-budget'),
        children: [
          TableRowBox(header: true, children: [
            cellText(context, t('Статья', 'Item', 'Modda'), flex: 3, bold: true),
            cellText(context, t('План', 'Plan', 'Reja'), bold: true, align: TextAlign.end),
            cellText(context, t('Осмотр', 'Inspected', 'Ko‘rik'), bold: true, align: TextAlign.end),
            cellText(context, t('Выдано', 'Paid', 'To‘langan'), bold: true, align: TextAlign.end),
          ]),
          for (final row in rows)
            TableRowBox(children: [
              cellText(context, row.s('title'), flex: 3),
              cellText(context, row['plan'] == null ? '—' : bankAmount(context, row['plan']), align: TextAlign.end),
              cellText(
                context,
                row['percent'] == null ? t('нет данных', 'no data', 'ma’lumot yo‘q') : '${row.s('percent')}% · ${bankAmount(context, row['confirmed'])}',
                align: TextAlign.end,
                muted: row['percent'] == null,
              ),
              cellText(context, bankAmount(context, row['issued']), align: TextAlign.end),
            ]),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '${t('Суммы в', 'Amounts in', 'Summalar:')} ${bankUnit(context)}. ${t('«Осмотр» — процент готовности и подтверждённая сумма по последнему акту технадзора.', '“Inspected” is the percent complete and the confirmed amount from the latest supervision report.', '“Ko‘rik” — texnik nazoratning oxirgi dalolatnomasi bo‘yicha tayyorlik foizi va tasdiqlangan summa.')}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tranches(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final rows = data.list('tranches');
    if (rows.isEmpty) {
      return EmptyState(
        title: t('Траншей пока нет', 'No tranches yet', 'Transhlar hali yo‘q'),
        body: t('Застройщик ещё не отправлял заявок в банк.', 'The developer has not sent any request to the bank.', 'Quruvchi hali bankka ariza yubormagan.'),
      );
    }
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final row in rows)
          TableRowBox(
            key: Key('object-tranche-${row.s('id')}'),
            onTap: () => context.go('/bank/tranches/${row.s('id')}'),
            children: [
              SizedBox(width: 60, child: Text(BankStrings.of(context).trancheNo(row.i('no')), style: theme.textTheme.titleSmall)),
              cellText(context, row.s('stage_label'), flex: 2),
              cellText(context, '${bankAmount(context, row['requested'])} ${bankUnit(context)}', align: TextAlign.end),
              cellText(context, fmtDay(row['submitted']), muted: true, align: TextAlign.end),
            ],
          ),
      ]),
    );
  }

  Widget _inspections(BuildContext context, Tx t) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final rows = data.list('inspections');
    if (rows.isEmpty) {
      return EmptyState(
        title: t('Осмотров нет', 'No inspections', 'Ko‘riklar yo‘q'),
        body: t('Назначить осмотр можно в разделе «Осмотры».', 'You can plan one in the Inspections section.', 'Ko‘rikni “Ko‘riklar” bo‘limida tayinlash mumkin.'),
      );
    }
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 100, child: Text(fmtDay(row['scheduled']), style: theme.textTheme.titleSmall)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${inspectionKind(t, row.s('kind'))} · ${row.s('expert').isEmpty ? t('эксперт не назначен', 'no expert assigned', 'ekspert tayinlanmagan') : row.s('expert')}',
                      style: theme.textTheme.bodyMedium),
                  if (row.s('status') == 'done')
                    Text(
                      '${t('Риск', 'Risk', 'Xavf')}: ${inspectionRisk(t, row.s('risk'))} · ${inspectionRecommendation(t, row.s('recommendation'))}'
                      '${row.s('finish').isEmpty ? '' : ' · ${t('прогноз сдачи', 'forecast', 'prognoz')} ${fmtDay(row['finish'])}'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                  if (row.s('note').isNotEmpty) Text(row.s('note'), style: theme.textTheme.bodySmall),
                ]),
              ),
              inspectionTag(context, t, row.s('status')),
            ]),
          ),
      ]),
    );
  }

  Widget _documents(BuildContext context, Tx t) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final rows = data.list('documents');
    if (rows.isEmpty) {
      return EmptyState(
        title: t('Документов нет', 'No documents', 'Hujjatlar yo‘q'),
        body: t('Застройщик не добавил разрешения и акты.', 'The developer has not added permits and acts.', 'Quruvchi ruxsatnoma va dalolatnomalarni qo‘shmagan.'),
      );
    }
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final row in rows)
          TableRowBox(children: [
            cellText(context, row.s('title'), flex: 3),
            cellText(context, row.s('number'), muted: true),
            Text(fmtDay(row['issued']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
          ]),
      ]),
    );
  }

  Widget _filings(BuildContext context, Tx t) {
    final rows = data.list('filings');
    if (rows.isEmpty) {
      return EmptyState(
        title: t('Отчётов не было', 'No reports received', 'Hisobotlar kelmagan'),
        body: t('Принятые отчёты о продажах и квартальные отчёты появятся здесь.', 'Received sales and quarterly reports will appear here.', 'Qabul qilingan sotuv va choraklik hisobotlar shu yerda ko‘rinadi.'),
      );
    }
    return IBuildCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (final row in rows)
          TableRowBox(children: [
            cellText(context, row.s('kind') == 'sales' ? t('Отчёт о продажах', 'Sales report', 'Sotuv hisoboti') : t('Квартальный отчёт', 'Quarterly report', 'Choraklik hisobot'), flex: 2),
            cellText(context, fmtDay(row['period']), muted: true),
            cellText(context, '${t('получен', 'received', 'qabul qilindi')} ${fmtDay(row['filed'])}', muted: true, align: TextAlign.end),
          ]),
      ]),
    );
  }
}

String inspectionKind(Tx t, String kind) {
  return kind == 'regular' ? t('Плановый осмотр', 'Regular inspection', 'Rejali ko‘rik') : t('Контрольный замер', 'Control measurement', 'Nazorat o‘lchovi');
}

String inspectionRisk(Tx t, String risk) {
  return switch (risk) {
    'high' => t('высокий', 'high', 'yuqori'),
    'watch' => t('наблюдать', 'watch', 'kuzatish'),
    'ok' => t('низкий', 'low', 'past'),
    _ => '—',
  };
}

String inspectionRecommendation(Tx t, String value) {
  return switch (value) {
    'issue' => t('рекомендует выдать', 'recommends paying out', 'to‘lashni tavsiya qiladi'),
    'withhold' => t('рекомендует удержать', 'recommends withholding', 'ushlab turishni tavsiya qiladi'),
    _ => '—',
  };
}

Widget inspectionTag(BuildContext context, Tx t, String status) {
  final colors = context.colors;
  return switch (status) {
    'done' => Tag(label: t('Выполнен', 'Done', 'Bajarilgan'), color: colors.success),
    'overdue' => Tag(label: t('Просрочен', 'Overdue', 'Muddati o‘tgan'), color: colors.danger),
    _ => Tag(label: t('Запланирован', 'Planned', 'Rejalashtirilgan'), color: bankBlue(context)),
  };
}
