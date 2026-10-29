import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';

String bankActionName(Tx t, String action) {
  return switch (action) {
    'vote' => t('Голос в согласовании', 'A vote in the approval', 'Kelishuvdagi ovoz'),
    'inspection_reported' => t('Получен акт технадзора', 'A supervision report arrived', 'Texnik nazorat dalolatnomasi keldi'),
    'tranche_created' => t('Транш поступил в банк', 'A tranche reached the bank', 'Transh bankka tushdi'),
    'choose' => t('Выбрана сумма по статье', 'An amount chosen for an item', 'Modda bo‘yicha summa tanlandi'),
    'decision' => t('Решение по траншу', 'A decision on a tranche', 'Transh bo‘yicha qaror'),
    'request' => t('Запрошен документ', 'A document was requested', 'Hujjat so‘raldi'),
    'resume' => t('Транш возвращён в работу', 'A tranche was resumed', 'Transh qayta ishga olindi'),
    'waive' => t('Принято с обоснованием', 'Accepted with a reason', 'Asos bilan qabul qilindi'),
    'filing_received' => t('Получен отчёт застройщика', 'A developer report received', 'Quruvchi hisoboti olindi'),
    'inspection_done' => t('Осмотр выполнен', 'An inspection done', 'Ko‘rik bajarildi'),
    'inspection_planned' => t('Осмотр назначен', 'An inspection planned', 'Ko‘rik tayinlandi'),
    'reminder' => t('Напоминание застройщику', 'A reminder to the developer', 'Quruvchiga eslatma'),
    'report_exported' => t('Выгружен отчёт', 'A report exported', 'Hisobot yuklab olindi'),
    'report_schedule' => t('Изменено расписание отчёта', 'A report schedule changed', 'Hisobot jadvali o‘zgartirildi'),
    'rules_saved' => t('Сохранена новая версия правил', 'A new rules version saved', 'Qoidalarning yangi versiyasi saqlandi'),
    'rules_group' => t('Изменена группа согласования', 'An approval group changed', 'Kelishuv guruhi o‘zgartirildi'),
    'rules_member' => t('Изменён отпуск сотрудника', 'An employee’s leave changed', 'Xodim ta’tili o‘zgartirildi'),
    _ => action,
  };
}

/// The journal of the whole bank: who did what and when. Read only.
class BankAuditScreen extends StatefulWidget {
  const BankAuditScreen({super.key});

  @override
  State<BankAuditScreen> createState() => _BankAuditScreenState();
}

class _BankAuditScreenState extends State<BankAuditScreen> {
  String _action = '';
  String _query = '';
  String _from = '';
  String _to = '';

  String get _path {
    final params = [
      if (_action.isNotEmpty) 'action=$_action',
      if (_query.isNotEmpty) 'q=${Uri.encodeQueryComponent(_query)}',
      if (_from.isNotEmpty) 'from=$_from',
      if (_to.isNotEmpty) 'to=$_to',
      'limit=200',
    ];
    return '/api/bank/audit?${params.join('&')}';
  }

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: _path,
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        final actions = (data['actions'] as List? ?? const []).map((a) => '$a').toList();
        return ScreenScroll(
          key: const Key('bank-audit-frame'),
          children: [
            PageTitle(
              title: t('Журнал банка', 'Bank journal', 'Bank jurnali'),
              subtitle: t('Кто, что и когда сделал: решения, осмотры, правила, выгрузки', 'Who did what and when: decisions, inspections, rules, exports', 'Kim, nima va qachon qildi: qarorlar, ko‘riklar, qoidalar, yuklab olishlar'),
            ),
            Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('audit-action-$_action'),
                  isExpanded: true,
                  initialValue: _action,
                  decoration: InputDecoration(labelText: t('Действие', 'Action', 'Harakat'), isDense: true),
                  items: [DropdownMenuItem(value: '', child: Text(t('Все', 'All', 'Hammasi'))), for (final a in actions) DropdownMenuItem(value: a, child: Text(bankActionName(t, a), overflow: TextOverflow.ellipsis))],
                  onChanged: (value) => setState(() => _action = value ?? ''),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  key: const Key('audit-search'),
                  onSubmitted: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(hintText: t('Сотрудник или объект, Enter', 'Employee or project, Enter', 'Xodim yoki obyekt, Enter'), prefixIcon: const Icon(Icons.search), isDense: true),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('audit-from'),
                onPressed: () async {
                  final day = await pickDay(context, initial: _from.isEmpty ? null : _from);
                  if (day != null) setState(() => _from = day);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(_from.isEmpty ? t('С даты', 'From', 'Dan') : fmtDay(_from)),
              ),
              OutlinedButton.icon(
                key: const Key('audit-to'),
                onPressed: () async {
                  final day = await pickDay(context, initial: _to.isEmpty ? null : _to);
                  if (day != null) setState(() => _to = day);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(_to.isEmpty ? t('По дату', 'To', 'Gacha') : fmtDay(_to)),
              ),
              if (_from.isNotEmpty || _to.isNotEmpty || _query.isNotEmpty || _action.isNotEmpty)
                TextButton(
                  key: const Key('audit-clear'),
                  onPressed: () => setState(() {
                    _from = '';
                    _to = '';
                    _query = '';
                    _action = '';
                  }),
                  child: Text(t('Сбросить', 'Clear', 'Tozalash')),
                ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(
                title: t('Записей нет', 'No entries', 'Yozuvlar yo‘q'),
                body: t('По этим условиям событий не найдено.', 'No events for these conditions.', 'Bu shartlar bo‘yicha hodisalar topilmadi.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('audit-list'),
                  children: [
                    for (final item in items)
                      TableRowBox(
                        onTap: item.s('tranche_id').isEmpty ? null : () => context.go('/bank/tranches/${item.s('tranche_id')}'),
                        children: [
                          SizedBox(width: 130, child: Text(fmtTime(item['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted))),
                          Expanded(
                            flex: 3,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(bankActionName(t, item.s('action')), style: theme.textTheme.bodyMedium),
                              if (item.s('project').isNotEmpty) Text(item.s('project'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                            ]),
                          ),
                          cellText(context, item.s('actor'), flex: 2, muted: true),
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
