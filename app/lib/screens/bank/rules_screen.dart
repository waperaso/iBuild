import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../money.dart';
import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';
import 'portfolio_screen.dart' show bankStageName;

String _ruleLabel(Tx t, String key) {
  return switch (key) {
    'committeeAmount' => t('Порог комитета', 'Committee threshold', 'Qo‘mita chegarasi'),
    'issuedAbovePercent' => t('Допуск «выдано сверх подтверждённого»', 'Tolerance for “paid above confirmed”', '“Tasdiqlangandan ortiq to‘langan” ruxsati'),
    'scheduleLagMonths' => t('Отставание от графика', 'Lag behind the schedule', 'Jadvaldan ortda qolish'),
    'forecastWarningDays' => t('Прогноз: предупреждение', 'Forecast: warning', 'Prognoz: ogohlantirish'),
    'forecastRedMonths' => t('Прогноз: красный сигнал', 'Forecast: red signal', 'Prognoz: qizil signal'),
    'salesReportDays' => t('Дни отчёта о продажах', 'Sales report days', 'Sotuv hisoboti kunlari'),
    'remindGroup' => t('Напоминать группе', 'Remind the group', 'Guruhga eslatish'),
    'stages' => t('Сроки этапов', 'Step terms', 'Bosqich muddatlari'),
    'documents' => t('Документы транша', 'Tranche documents', 'Transh hujjatlari'),
    _ => key,
  };
}

String _ownerName(Tx t, String owner) {
  return switch (owner) {
    'specialist' => t('Кредитный специалист', 'Credit specialist', 'Kredit mutaxassisi'),
    'expert' => t('Эксперт', 'Expert', 'Ekspert'),
    'head' => t('Руководитель', 'Head', 'Rahbar'),
    'committee' => t('Комитет', 'Committee', 'Qo‘mita'),
    _ => t('Платёжный отдел', 'Payments', 'To‘lov bo‘limi'),
  };
}

String _groupName(Tx t, String code, String fallback) {
  return switch (code) {
    'heads' => t('Начальники отделов', 'Heads of departments', 'Bo‘lim boshliqlari'),
    'committee' => t('Кредитный комитет', 'Credit committee', 'Kredit qo‘mitasi'),
    _ => fallback,
  };
}

class BankRulesScreen extends StatelessWidget {
  const BankRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final role = SessionScope.of(context).user?.bank?.role;
    if (role != 'admin') {
      return ScreenScroll(
        key: const Key('bank-rules-frame'),
        children: [
          PageTitle(title: LocaleScope.copy(context).bankRules),
          EmptyState(
            key: const Key('rules-denied'),
            title: t('Раздел для администратора банка', 'A section for the bank administrator', 'Bank administratori uchun bo‘lim'),
            body: t('Правила и маршруты меняет администратор. Остальные видят их в карточках траншей.',
                'The administrator changes the rules and routes. Others see them in the tranche cards.', 'Qoidalar va marshrutlarni administrator o‘zgartiradi. Boshqalar ularni transh kartalarida ko‘radi.'),
          ),
        ],
      );
    }
    return JsonLoader(
      path: '/api/bank/rules',
      builder: (context, data, reload) => _RulesView(key: ValueKey('rules-${data.i('version')}-${data.list('groups').length}'), data: data, reload: reload),
    );
  }
}

class _RulesView extends StatefulWidget {
  const _RulesView({super.key, required this.data, required this.reload});

  final Map<String, dynamic> data;
  final Future<void> Function() reload;

  @override
  State<_RulesView> createState() => _RulesViewState();
}

class _RulesViewState extends State<_RulesView> {
  String _tab = 'thresholds';
  late final Map<String, dynamic> _rules = Map<String, dynamic>.from(widget.data.obj('rules'));
  late final _committee = TextEditingController(text: _wholeSums(_rules['committeeAmount']));
  late final _above = TextEditingController(text: '${_rules['issuedAbovePercent']}');
  late final _lag = TextEditingController(text: '${_rules['scheduleLagMonths']}');
  late final _warn = TextEditingController(text: '${_rules['forecastWarningDays']}');
  late final _red = TextEditingController(text: '${_rules['forecastRedMonths']}');
  late final _sales = TextEditingController(text: ((_rules['salesReportDays'] as List?) ?? const []).join(', '));
  final _note = TextEditingController();
  late bool _remind = _rules['remindGroup'] != false;
  late final List<Map<String, dynamic>> _stages = [for (final s in (_rules['stages'] as List)) Map<String, dynamic>.from(s as Map)];
  late final List<Map<String, dynamic>> _documents = [for (final d in (_rules['documents'] as List)) Map<String, dynamic>.from(d as Map)];
  String? _error;
  bool _busy = false;

  static String _wholeSums(Object? value) {
    final text = '${value ?? ''}';
    final dot = text.indexOf('.');
    return dot < 0 ? text : text.substring(0, dot);
  }

  @override
  void dispose() {
    for (final c in [_committee, _above, _lag, _warn, _red, _sales, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = Tx.of(context);
    final salesDays = [
      for (final part in _sales.text.split(RegExp(r'[,;\s]+')))
        if (part.isNotEmpty) int.tryParse(part),
    ];
    final above = int.tryParse(_above.text.trim());
    final lag = int.tryParse(_lag.text.trim());
    final warn = int.tryParse(_warn.text.trim());
    final red = int.tryParse(_red.text.trim());
    if (!RegExp(r'^\d{1,15}$').hasMatch(_committee.text.trim()) ||
        above == null ||
        lag == null ||
        warn == null ||
        red == null ||
        salesDays.isEmpty ||
        salesDays.contains(null)) {
      setState(() => _error = t('Проверьте числа: все поля нужно заполнить цифрами.', 'Check the numbers: every field must be filled with digits.',
          'Raqamlarni tekshiring: barcha maydonlar raqamlar bilan to‘ldirilishi kerak.'));
      setState(() => _tab = 'thresholds');
      return;
    }
    final body = <String, Object?>{
      'committeeAmount': _committee.text.trim(),
      'issuedAbovePercent': above,
      'scheduleLagMonths': lag,
      'forecastWarningDays': warn,
      'forecastRedMonths': red,
      'salesReportDays': salesDays,
      'remindGroup': _remind,
      'stages': _stages,
      'documents': _documents,
      'note': _note.text.trim(),
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = SessionScope.of(context).api;
    try {
      await api.postJson('/api/bank/rules', body);
      await widget.reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return ScreenScroll(
      key: const Key('bank-rules-frame'),
      children: [
        PageTitle(
          title: LocaleScope.copy(context).bankRules,
          subtitle: t('Версия ${widget.data.i('version')} действует с ${fmtDay(widget.data['effectiveFrom'])}. Каждое изменение создаёт новую версию: новые транши идут по ней, начатые заканчиваются по прежней.',
              'Version ${widget.data.i('version')} has been in force since ${fmtDay(widget.data['effectiveFrom'])}. Every change makes a new version: new tranches follow it, tranches already started finish under the old one.',
              '${widget.data.i('version')}-versiya ${fmtDay(widget.data['effectiveFrom'])} dan kuchda. Har bir o‘zgarish yangi versiya yaratadi: yangi transhlar shu bo‘yicha, boshlanganlari eskisi bo‘yicha tugaydi.'),
        ),
        FilterChips(
          keyPrefix: 'rules-tab',
          value: _tab,
          onChanged: (value) => setState(() => _tab = value),
          options: [
            ('thresholds', t('Пороги и сроки', 'Thresholds and terms', 'Chegaralar va muddatlar')),
            ('documents', t('Документы', 'Documents', 'Hujjatlar')),
            ('groups', t('Группы согласования', 'Approval groups', 'Kelishuv guruhlari')),
            ('history', t('Журнал изменений', 'Change log', 'O‘zgarishlar jurnali')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_tab == 'thresholds') _thresholds(context, t),
        if (_tab == 'documents') _documentsTab(context, t),
        if (_tab == 'groups') _groups(context, t),
        if (_tab == 'history') _history(context, t),
        if (_tab == 'thresholds' || _tab == 'documents') ...[
          const SizedBox(height: AppSpacing.xl),
          IBuildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('rules-note'),
                  controller: _note,
                  maxLength: 500,
                  decoration: InputDecoration(labelText: t('Что и почему меняете (попадёт в журнал)', 'What and why (goes to the log)', 'Nima va nima uchun o‘zgartirilmoqda (jurnalga tushadi)')),
                ),
                if (_error != null) ...[const SizedBox(height: AppSpacing.sm), ErrorNote(message: _error!)],
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('rules-save'),
                  label: t('Сохранить как версию ${widget.data.i('version') + 1}', 'Save as version ${widget.data.i('version') + 1}', '${widget.data.i('version') + 1}-versiya sifatida saqlash'),
                  busy: _busy,
                  onPressed: _save,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t('Проверки, которые требует договор, остаются всегда: их нельзя отключить.', 'The checks the contract demands always stay: they cannot be turned off.', 'Shartnoma talab qiladigan tekshiruvlar doim qoladi: ularni o‘chirib bo‘lmaydi.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _numberField(String key, String label, TextEditingController controller, {String? suffix, double width = 220}) {
    return SizedBox(
      width: width,
      child: TextField(
        key: Key(key),
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      ),
    );
  }

  Widget _thresholds(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Column(
      key: const Key('rules-thresholds'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBuildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('Пороги', 'Thresholds', 'Chegaralar'), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.md, children: [
              _numberField('rule-committee', t('Транш выше этой суммы идёт в комитет', 'Tranches above this go to the committee', 'Shundan yuqori transhlar qo‘mitaga boradi'), _committee, suffix: t('сум', 'UZS', 'so‘m'), width: 340),
              _numberField('rule-above', t('Выдано сверх подтверждённого', 'Paid above confirmed', 'Tasdiqlangandan ortiq to‘langan'), _above, suffix: '%'),
              _numberField('rule-lag', t('Отставание от графика', 'Lag behind schedule', 'Jadvaldan ortda qolish'), _lag, suffix: t('мес.', 'mo', 'oy')),
              _numberField('rule-warn', t('Прогноз позже срока: предупреждение', 'Forecast past term: warning', 'Prognoz muddatdan keyin: ogohlantirish'), _warn, suffix: t('дн.', 'd', 'kun'), width: 300),
              _numberField('rule-red', t('Прогноз позже срока: красный', 'Forecast past term: red', 'Prognoz muddatdan keyin: qizil'), _red, suffix: t('мес.', 'mo', 'oy'), width: 300),
              SizedBox(
                width: 260,
                child: TextField(
                  key: const Key('rule-sales'),
                  controller: _sales,
                  decoration: InputDecoration(labelText: t('Дни отчёта о продажах', 'Sales report days', 'Sotuv hisoboti kunlari'), helperText: t('числа месяца, через запятую', 'days of the month, comma separated', 'oy kunlari, vergul bilan')),
                ),
              ),
            ]),
            SwitchListTile(
              key: const Key('rule-remind'),
              contentPadding: EdgeInsets.zero,
              value: _remind,
              onChanged: (value) => setState(() => _remind = value),
              title: Text(t('Напоминать группе, если этап подходит к сроку', 'Remind the group when a step nears its term', 'Bosqich muddatiga yaqinlashsa guruhga eslatish')),
            ),
            Text(
              '${t('Сейчас порог комитета', 'Committee threshold now', 'Hozirgi qo‘mita chegarasi')}: ${moneyMillions(_wholeSums(_committee.text).isEmpty ? '0' : '${_wholeSums(_committee.text)}.00')} ${t('млн сум', 'm UZS', 'mln so‘m')}',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        IBuildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('Маршрут и сроки этапов', 'Route and step terms', 'Marshrut va bosqich muddatlari'), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _stages.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SizedBox(width: 150, child: Text('${i + 1}. ${bankStageName(t, '${_stages[i]['code']}')}', style: theme.textTheme.titleSmall)),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: Key('stage-owner-${_stages[i]['code']}'),
                      isExpanded: true,
                      initialValue: '${_stages[i]['owner']}',
                      decoration: InputDecoration(labelText: t('Исполнитель', 'Owner', 'Ijrochi'), isDense: true),
                      items: [for (final owner in const ['specialist', 'expert', 'head', 'committee', 'payment']) DropdownMenuItem(value: owner, child: Text(_ownerName(t, owner)))],
                      onChanged: (value) => setState(() => _stages[i]['owner'] = value),
                    ),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      key: Key('stage-less-${_stages[i]['code']}'),
                      onPressed: (_stages[i]['days'] as int) > 1 ? () => setState(() => _stages[i]['days'] = (_stages[i]['days'] as int) - 1) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(width: 70, child: Text('${_stages[i]['days']} ${t('раб. дн.', 'wd', 'ish kuni')}', textAlign: TextAlign.center, key: Key('stage-days-${_stages[i]['code']}'))),
                    IconButton(
                      key: Key('stage-more-${_stages[i]['code']}'),
                      onPressed: (_stages[i]['days'] as int) < 30 ? () => setState(() => _stages[i]['days'] = (_stages[i]['days'] as int) + 1) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ]),
                ]),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t('Выплата в системе блокируется до ЭЦП и платёжки АБС: эта часть маршрута не настраивается.', 'The payout stays locked until the e-signature and the banking-system payment: this part of the route is fixed.', 'To‘lov ERI va ABT to‘lov topshirig‘igacha bloklanadi: marshrutning bu qismi sozlanmaydi.'),
              style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _documentsTab(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Column(
      key: const Key('rules-documents'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _documents.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: IBuildCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      key: Key('doc-title-$i'),
                      initialValue: '${_documents[i]['title']}',
                      decoration: InputDecoration(labelText: t('Документ', 'Document', 'Hujjat')),
                      onChanged: (value) => _documents[i]['title'] = value,
                    ),
                  ),
                  IconButton(
                    key: Key('doc-remove-$i'),
                    tooltip: t('Убрать', 'Remove', 'Olib tashlash'),
                    onPressed: () => setState(() => _documents.removeAt(i)),
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      key: Key('doc-when-$i'),
                      initialValue: '${_documents[i]['when']}',
                      decoration: InputDecoration(labelText: t('Когда нужен', 'When needed', 'Qachon kerak')),
                      onChanged: (value) => _documents[i]['when'] = value,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextFormField(
                      key: Key('doc-obligation-$i'),
                      initialValue: '${_documents[i]['obligation']}',
                      decoration: InputDecoration(labelText: t('Обязательность', 'Obligation', 'Majburiyat')),
                      onChanged: (value) => _documents[i]['obligation'] = value,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      key: Key('doc-basis-$i'),
                      initialValue: '${_documents[i]['basis']}',
                      decoration: InputDecoration(labelText: t('Основание', 'Basis', 'Asos')),
                      onChanged: (value) => _documents[i]['basis'] = value,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: Key('doc-effect-$i'),
                      isExpanded: true,
                      initialValue: '${_documents[i]['effect']}',
                      decoration: InputDecoration(labelText: t('Без него', 'Without it', 'Usiz')),
                      items: [
                        DropdownMenuItem(value: 'block', child: Text(t('Блокирует выдачу', 'Blocks the payout', 'To‘lovni bloklaydi'))),
                        DropdownMenuItem(value: 'warning', child: Text(t('Предупреждение', 'Warning only', 'Faqat ogohlantirish'))),
                      ],
                      onChanged: (value) => setState(() => _documents[i]['effect'] = value),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('doc-add'),
            onPressed: () => setState(() {
              var n = _documents.length + 1;
              while (_documents.any((d) => d['code'] == 'doc_$n')) {
                n++;
              }
              _documents.add({'code': 'doc_$n', 'title': '', 'when': '', 'obligation': '', 'effect': 'warning', 'basis': ''});
            }),
            icon: const Icon(Icons.add),
            label: Text(t('Добавить документ', 'Add a document', 'Hujjat qo‘shish')),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t('Список записывается в версию правил. Разработчик увидит его в требованиях к траншу после того, как проверка документов начнёт читать эти правила.',
              'The list is stored in the rules version. Developers will see it in the tranche requirements once the document check reads these rules.',
              'Ro‘yxat qoidalar versiyasiga yoziladi. Hujjatlar tekshiruvi bu qoidalarni o‘qiy boshlagach, quruvchi uni transh talablarida ko‘radi.'),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }

  Widget _groups(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final groups = widget.data.list('groups');
    return Column(
      key: const Key('rules-groups'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: IBuildCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_groupName(t, group.s('code'), group.s('name')), style: theme.textTheme.titleLarge)),
                  Text(t('Нужно согласий', 'Approvals needed', 'Kerakli kelishuvlar'), style: theme.textTheme.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  DropdownButton<int>(
                    key: Key('quorum-${group.s('code')}'),
                    value: group.i('required'),
                    items: [for (var n = 1; n <= (group.list('members').length.clamp(1, 20)); n++) DropdownMenuItem(value: n, child: Text('$n'))],
                    onChanged: (value) async {
                      if (value == null || value == group.i('required')) return;
                      final api = SessionScope.of(context).api;
                      final ok = await runAction(context, () => api.postJson('/api/bank/rules/groups/${group.s('code')}', {'requiredApprovals': value}));
                      if (ok) await widget.reload();
                    },
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                for (final member in group.list('members'))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(member.s('name'), style: theme.textTheme.titleSmall),
                          Text('${member.s('title')} · ${member.s('branch')}', style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                        ]),
                      ),
                      if (member.s('onLeaveUntil').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Tag(label: '${t('в отпуске до', 'on leave until', 'ta’tilda, gacha')} ${fmtDay(member['onLeaveUntil'])}', color: colors.warning),
                        ),
                      TextButton(
                        key: Key('leave-${member.s('userId')}'),
                        onPressed: () async {
                          final api = SessionScope.of(context).api;
                          if (member.s('onLeaveUntil').isNotEmpty) {
                            final ok = await runAction(context, () => api.postJson('/api/bank/rules/members/${member.s('userId')}', {'onLeaveUntil': null}));
                            if (ok) await widget.reload();
                            return;
                          }
                          final day = await pickDay(context, first: DateTime.now());
                          if (day == null || !context.mounted) return;
                          final ok = await runAction(context, () => api.postJson('/api/bank/rules/members/${member.s('userId')}', {'onLeaveUntil': day}));
                          if (ok) await widget.reload();
                        },
                        child: Text(member.s('onLeaveUntil').isNotEmpty ? t('Вернуть из отпуска', 'End the leave', 'Ta’tilni tugatish') : t('Отпуск до…', 'Leave until…', 'Ta’til, gacha…')),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
        Text(
          t('Человек в отпуске не голосует, а кворум считается по тем, кто на месте.', 'A person on leave does not vote, and the quorum counts those who are present.', 'Ta’tildagi kishi ovoz bermaydi, kvorum joyidagilar bo‘yicha hisoblanadi.'),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }

  Widget _history(BuildContext context, Tx t) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final history = widget.data.list('history');
    final changes = widget.data.list('changes').where((c) => c.s('action') != 'rules_saved').toList();
    return Column(
      key: const Key('rules-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IBuildCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final row in history)
              Column(children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 90, child: Text(t('Версия ${row.i('version')}', 'Version ${row.i('version')}', '${row.i('version')}-versiya'), style: theme.textTheme.titleSmall)),
                    SizedBox(width: 100, child: Text(fmtDay(row['effectiveFrom']), style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          (row['changed'] as List).isEmpty ? t('Первая версия', 'The first version', 'Birinchi versiya') : (row['changed'] as List).map((k) => _ruleLabel(t, '$k')).join(', '),
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (row.s('note').isNotEmpty) Text(row.s('note'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                        if (row.s('author').isNotEmpty) Text(row.s('author'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                      ]),
                    ),
                  ]),
                ),
                Divider(height: 1, color: colors.outline),
              ]),
          ]),
        ),
        if (changes.isNotEmpty) ...[
          SectionTitle(t('Группы и отпуска', 'Groups and leave', 'Guruhlar va ta’tillar')),
          IBuildCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final c in changes)
                TableRowBox(children: [
                  SizedBox(width: 130, child: Text(fmtTime(c['created_at']), style: theme.textTheme.bodySmall)),
                  Expanded(child: Text(c.s('action') == 'rules_group' ? t('Изменено число согласий группы', 'The approvals of a group changed', 'Guruh kelishuvlari soni o‘zgartirildi') : t('Изменён отпуск сотрудника', 'An employee’s leave changed', 'Xodim ta’tili o‘zgartirildi'))),
                  Text(c.s('actor_label'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                ]),
            ]),
          ),
        ],
      ],
    );
  }
}
