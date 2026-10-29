import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';
import 'objects_screen.dart' show inspectionKind, inspectionRecommendation, inspectionRisk, inspectionTag;

class BankInspectionsScreen extends StatefulWidget {
  const BankInspectionsScreen({super.key});

  @override
  State<BankInspectionsScreen> createState() => _BankInspectionsScreenState();
}

class _BankInspectionsScreenState extends State<BankInspectionsScreen> {
  String _filter = 'planned';

  Future<void> _plan(Map<String, dynamic> data, Future<void> Function() reload) async {
    final done = await showPlainDialog<bool>(
      context: context,
      builder: (context) => _PlanDialog(objects: data.list('objects'), experts: data.list('experts')),
    );
    if (done == true) await reload();
  }

  Future<void> _complete(Map<String, dynamic> item, Future<void> Function() reload) async {
    final done = await showPlainDialog<bool>(context: context, builder: (context) => _CompleteDialog(item: item));
    if (done == true) await reload();
  }

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/bank/inspections',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final counts = data.obj('counts');
        final me = SessionScope.of(context).user;
        final admin = me?.bank?.role == 'admin';
        final all = data.list('items');
        final items = [
          for (final item in all)
            if (_filter == 'all' || item.s('status') == _filter) item,
        ];
        return ScreenScroll(
          key: const Key('bank-inspections-frame'),
          children: [
            PageTitle(
              title: LocaleScope.copy(context).bankInspections,
              subtitle: t('Выезды экспертов банка на объекты', 'Visits of the bank experts to the sites', 'Bank ekspertlarining obyektlarga chiqishlari'),
              trailing: data.b('canPlan')
                  ? PrimaryButton(key: const Key('plan-inspection'), label: t('Назначить осмотр', 'Plan an inspection', 'Ko‘rik tayinlash'), onPressed: () => _plan(data, reload))
                  : null,
            ),
            KpiRow(children: [
              Kpi(label: t('Запланировано', 'Planned', 'Rejalashtirilgan'), value: '${counts.i('planned')}'),
              Kpi(label: t('Выполнено', 'Done', 'Bajarilgan'), value: '${counts.i('done')}'),
              Kpi(label: t('Просрочено', 'Overdue', 'Muddati o‘tgan'), value: '${counts.i('overdue')}', tone: counts.i('overdue') > 0 ? colors.danger : null),
            ]),
            const SizedBox(height: AppSpacing.lg),
            FilterChips(
              keyPrefix: 'inspections-filter',
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              options: [
                ('planned', t('Запланированы', 'Planned', 'Rejalashtirilgan')),
                ('overdue', t('Просрочены', 'Overdue', 'Muddati o‘tgan')),
                ('done', t('Выполнены', 'Done', 'Bajarilgan')),
                ('all', t('Все', 'All', 'Hammasi')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(
                title: t('Здесь пусто', 'Nothing here', 'Bu yerda hech narsa yo‘q'),
                body: t('Осмотров с таким статусом нет.', 'No inspections with this status.', 'Bunday holatdagi ko‘riklar yo‘q.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('inspections-list'),
                  children: [
                    for (final item in items)
                      Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(
                              width: 100,
                              child: Text(fmtDay(item['status'] == 'done' ? item['completed'] : item['scheduled']), style: theme.textTheme.titleSmall),
                            ),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                InkWell(
                                  onTap: () => context.go('/bank/objects/${item.s('project_id')}'),
                                  child: Text(item.s('project_name'), style: theme.textTheme.titleSmall),
                                ),
                                Text(
                                  '${inspectionKind(t, item.s('kind'))} · ${item.s('expert').isEmpty ? t('эксперт не назначен', 'no expert assigned', 'ekspert tayinlanmagan') : item.s('expert')}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                                ),
                                if (item.s('status') == 'done')
                                  Text(
                                    '${t('Риск', 'Risk', 'Xavf')}: ${inspectionRisk(t, item.s('risk'))} · ${inspectionRecommendation(t, item.s('recommendation'))}'
                                    '${item.s('finish').isEmpty ? '' : ' · ${t('прогноз сдачи', 'forecast', 'prognoz')} ${fmtDay(item['finish'])}'}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (item.s('note').isNotEmpty) Text(item.s('note'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                              ]),
                            ),
                            inspectionTag(context, t, item.s('status')),
                            if (data.b('canComplete') && item.s('status') != 'done' && (admin || item.s('expert_id') == me?.id))
                              Padding(
                                padding: const EdgeInsets.only(left: AppSpacing.md),
                                child: OutlinedButton(
                                  key: Key('complete-${item.s('id')}'),
                                  onPressed: () => _complete(item, reload),
                                  child: Text(t('Закрыть осмотр', 'Close the visit', 'Ko‘rikni yopish')),
                                ),
                              ),
                          ]),
                        ),
                        Divider(height: 1, color: colors.outline),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({required this.objects, required this.experts});

  final List<Map<String, dynamic>> objects;
  final List<Map<String, dynamic>> experts;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  String? _project;
  String _expert = '';
  String _kind = 'control';
  String _day = '';
  String? _error;
  bool _busy = false;

  Future<void> _save() async {
    final t = Tx.of(context);
    if (_project == null || _day.isEmpty) {
      setState(() => _error = t('Выберите объект и дату осмотра', 'Choose a project and an inspection date', 'Obyekt va ko‘rik sanasini tanlang'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = SessionScope.of(context).api;
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () => api.postJson('/api/bank/inspections', {
          'projectId': _project,
          'scheduledOn': _day,
          'kind': _kind,
          if (_expert.isNotEmpty) 'expertUserId': _expert,
        }));
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
    final width = dialogFieldWidth(context);
    return AlertDialog(
      title: Text(t('Назначить осмотр', 'Plan an inspection', 'Ko‘rik tayinlash')),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('plan-project'),
                isExpanded: true,
                initialValue: _project,
                decoration: InputDecoration(labelText: t('Объект', 'Project', 'Obyekt')),
                items: [for (final o in widget.objects) DropdownMenuItem(value: o.s('id'), child: Text(o.s('name'), overflow: TextOverflow.ellipsis))],
                onChanged: (value) => setState(() => _project = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('plan-kind'),
                isExpanded: true,
                initialValue: _kind,
                decoration: InputDecoration(labelText: t('Вид', 'Kind', 'Turi')),
                items: [
                  DropdownMenuItem(value: 'control', child: Text(inspectionKind(t, 'control'))),
                  DropdownMenuItem(value: 'regular', child: Text(inspectionKind(t, 'regular'))),
                ],
                onChanged: (value) => setState(() => _kind = value ?? 'control'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('plan-expert'),
                isExpanded: true,
                initialValue: _expert,
                decoration: InputDecoration(labelText: t('Эксперт', 'Expert', 'Ekspert')),
                items: [
                  DropdownMenuItem(value: '', child: Text(t('Наименее загруженный', 'The least loaded', 'Eng kam band'))),
                  for (final e in widget.experts) DropdownMenuItem(value: e.s('id'), child: Text(e.s('name'))),
                ],
                onChanged: (value) => setState(() => _expert = value ?? ''),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: const Key('plan-day'),
                onPressed: () async {
                  final day = await pickDay(context, initial: _day.isEmpty ? null : _day);
                  if (day != null) setState(() => _day = day);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(_day.isEmpty ? t('Дата осмотра', 'Inspection date', 'Ko‘rik sanasi') : fmtDay(_day)),
              ),
              if (_error != null) ...[const SizedBox(height: AppSpacing.md), ErrorNote(message: _error!)],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
        PrimaryButton(key: const Key('plan-save'), label: t('Назначить', 'Plan', 'Tayinlash'), busy: _busy, onPressed: _save),
      ],
    );
  }
}

/// The form of the expert after a visit: risk, a recommendation, a note, the forecast of completion.
class _CompleteDialog extends StatefulWidget {
  const _CompleteDialog({required this.item});

  final Map<String, dynamic> item;

  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  String _risk = '';
  String _recommendation = '';
  String _finish = '';
  final _note = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = Tx.of(context);
    if (_risk.isEmpty || _recommendation.isEmpty) {
      setState(() => _error = t('Укажите риск и рекомендацию', 'Give the risk and the recommendation', 'Xavf va tavsiyani kiriting'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = SessionScope.of(context).api;
    final navigator = Navigator.of(context);
    final ok = await runAction(
      context,
      () => api.postJson('/api/bank/inspections/${widget.item.s('id')}/complete', {
        'risk': _risk,
        'recommendation': _recommendation,
        'note': _note.text.trim(),
        if (_finish.isNotEmpty) 'expectedFinish': _finish,
      }),
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
    return AlertDialog(
      title: Text('${t('Осмотр', 'Inspection', 'Ko‘rik')}: ${widget.item.s('project_name')}'),
      content: SizedBox(
        width: dialogFieldWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('Риск объекта', 'Risk of the project', 'Obyekt xavfi')),
              const SizedBox(height: AppSpacing.sm),
              FilterChips(
                keyPrefix: 'risk',
                value: _risk,
                onChanged: (value) => setState(() => _risk = value),
                options: [('ok', inspectionRisk(t, 'ok')), ('watch', inspectionRisk(t, 'watch')), ('high', inspectionRisk(t, 'high'))],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t('Рекомендация по выдаче', 'Recommendation on payout', 'To‘lov bo‘yicha tavsiya')),
              const SizedBox(height: AppSpacing.sm),
              FilterChips(
                keyPrefix: 'recommendation',
                value: _recommendation,
                onChanged: (value) => setState(() => _recommendation = value),
                options: [('issue', inspectionRecommendation(t, 'issue')), ('withhold', inspectionRecommendation(t, 'withhold'))],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const Key('complete-note'),
                controller: _note,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(labelText: t('Заключение', 'Conclusion', 'Xulosa')),
              ),
              OutlinedButton.icon(
                key: const Key('complete-finish'),
                onPressed: () async {
                  final day = await pickDay(context, initial: _finish.isEmpty ? null : _finish);
                  if (day != null) setState(() => _finish = day);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(_finish.isEmpty ? t('Прогноз сдачи (по желанию)', 'Completion forecast (optional)', 'Topshirish prognozi (ixtiyoriy)') : fmtDay(_finish)),
              ),
              if (_error != null) ...[const SizedBox(height: AppSpacing.md), ErrorNote(message: _error!)],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
        PrimaryButton(key: const Key('complete-save'), label: t('Закрыть осмотр', 'Close the visit', 'Ko‘rikni yopish'), busy: _busy, onPressed: _save),
      ],
    );
  }
}
