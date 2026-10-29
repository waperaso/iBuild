import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../session_scope.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../kit.dart';

String adminActionName(Tx t, String action) {
  return switch (action) {
    'applications.status' => t('Изменён статус заявки', 'An application status changed', 'Ariza holati o‘zgartirildi'),
    'applications.approve' => t('Заявка одобрена, компания создана', 'An application approved, company created', 'Ariza ma’qullandi, kompaniya yaratildi'),
    'applications.calls' => t('Записан звонок по заявке', 'A call logged', 'Ariza bo‘yicha qo‘ng‘iroq yozildi'),
    'applications.notes' => t('Заметка к заявке', 'A note on an application', 'Arizaga izoh'),
    'applications.checks' => t('Отмечена проверка заявки', 'An application check marked', 'Ariza tekshiruvi belgilandi'),
    'changes.approve' => t('Правка объекта одобрена', 'A project change approved', 'Obyekt tahriri ma’qullandi'),
    'changes.reject' => t('Правка объекта отклонена', 'A project change rejected', 'Obyekt tahriri rad etildi'),
    'users.active' => t('Изменён доступ пользователя', 'A user’s access changed', 'Foydalanuvchi kirishi o‘zgartirildi'),
    'users.reset-password' => t('Выдан новый пароль', 'A new password issued', 'Yangi parol berildi'),
    _ => action,
  };
}

const _openStatuses = ['new', 'calling', 'docs_requested', 'in_review'];

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/admin/overview',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final counts = data.obj('counts');
        final apps = data.obj('applications');
        final open = _openStatuses.fold<int>(0, (sum, s) => sum + (apps[s] is num ? (apps[s] as num).toInt() : 0));
        final oldest = DateTime.tryParse(data.s('oldestOpenApplication'));
        final waiting = oldest == null ? null : DateTime.now().difference(oldest).inDays;
        final recent = data.list('recent');
        return ScreenScroll(
          key: const Key('admin-overview-frame'),
          children: [
            PageTitle(
              title: t('Обзор платформы', 'Platform overview', 'Platforma sharhi'),
              subtitle: t('Что ждёт вашего решения и как живёт платформа', 'What waits for your decision and how the platform is doing', 'Qaroringizni nima kutmoqda va platforma qanday ishlayapti'),
            ),
            if (open > 0 || counts.i('changes_pending') > 0)
              IBuildCard(
                key: const Key('admin-todo'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('Ждёт решения', 'Waiting for a decision', 'Qaror kutmoqda'), style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (open > 0)
                    ListTile(
                      key: const Key('todo-applications'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.how_to_reg_outlined),
                      title: Text(t('Заявки на регистрацию: $open', 'Registration applications: $open', 'Ro‘yxatdan o‘tish arizalari: $open')),
                      subtitle: waiting == null ? null : Text(t('Самая старая ждёт $waiting дн.', 'The oldest has waited $waiting days', 'Eng eskisi $waiting kundan beri kutmoqda')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/applications'),
                    ),
                  if (counts.i('changes_pending') > 0)
                    ListTile(
                      key: const Key('todo-changes'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(t('Правки объектов на проверке: ${counts.i('changes_pending')}', 'Project changes to review: ${counts.i('changes_pending')}', 'Ko‘rib chiqiladigan obyekt tahrirlari: ${counts.i('changes_pending')}')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/moderation'),
                    ),
                ]),
              )
            else
              IBuildCard(
                key: const Key('admin-todo-empty'),
                child: Text(t('Очередь пуста: новых заявок и правок нет.', 'The queue is empty: no new applications or changes.', 'Navbat bo‘sh: yangi ariza va tahrirlar yo‘q.'), style: theme.textTheme.bodyMedium),
              ),
            SectionTitle(t('Платформа в цифрах', 'The platform in numbers', 'Platforma raqamlarda')),
            KpiRow(children: [
              Kpi(label: t('Застройщики', 'Developers', 'Quruvchilar'), value: '${counts.i('developers')}'),
              Kpi(label: t('Банки', 'Banks', 'Banklar'), value: '${counts.i('banks')}'),
              Kpi(label: t('Объекты', 'Projects', 'Obyektlar'), value: '${counts.i('projects')}'),
              Kpi(label: t('Пользователи', 'Users', 'Foydalanuvchilar'), value: '${counts.i('users_active')}', hint: '${t('отключено', 'turned off', 'o‘chirilgan')}: ${counts.i('users_disabled')}'),
              Kpi(label: t('Транши в банках', 'Tranches in banks', 'Banklardagi transhlar'), value: '${counts.i('tranches')}', hint: '${t('с блоком', 'blocked', 'bloklangan')}: ${counts.i('tranches_blocked')}'),
              Kpi(label: t('Сессии сейчас', 'Sessions now', 'Hozirgi sessiyalar'), value: '${counts.i('sessions')}'),
              Kpi(
                label: t('Неудачные входы за сутки', 'Failed sign-ins in 24 h', 'Sutkadagi muvaffaqiyatsiz kirishlar'),
                value: '${counts.i('failed_logins')}',
                tone: counts.i('failed_logins') > 20 ? colors.danger : null,
              ),
            ]),
            SectionTitle(t('Заявки по статусам', 'Applications by status', 'Arizalar holatlar bo‘yicha')),
            IBuildCard(
              child: Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.md, children: [
                for (final status in const ['new', 'calling', 'docs_requested', 'in_review', 'approved', 'rejected'])
                  SizedBox(
                    width: 130,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${apps[status] ?? 0}', style: theme.textTheme.headlineMedium),
                      Text(_applicationStatus(t, status), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                    ]),
                  ),
              ]),
            ),
            SectionTitle(
              t('Последние действия', 'Latest actions', 'Oxirgi harakatlar'),
              trailing: TextButton(onPressed: () => context.go('/admin/events'), child: Text(t('Весь журнал', 'The whole journal', 'Butun jurnal'))),
            ),
            IBuildCard(
              padding: EdgeInsets.zero,
              child: recent.isEmpty
                  ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(t('Пока ничего.', 'Nothing yet.', 'Hozircha hech narsa.'), style: theme.textTheme.bodyMedium?.copyWith(color: colors.inkMuted)))
                  : Column(children: [
                      for (final item in recent)
                        TableRowBox(children: [
                          SizedBox(width: 130, child: Text(fmtTime(item['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted))),
                          Expanded(child: Text(adminActionName(t, item.s('action')))),
                          Text(item.s('actor'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                        ]),
                    ]),
            ),
          ],
        );
      },
    );
  }
}

String _applicationStatus(Tx t, String status) {
  return switch (status) {
    'new' => t('Новые', 'New', 'Yangi'),
    'calling' => t('Звонок', 'Calling', 'Qo‘ng‘iroq'),
    'docs_requested' => t('Ждём документы', 'Waiting for documents', 'Hujjatlar kutilmoqda'),
    'in_review' => t('На проверке', 'In review', 'Tekshiruvda'),
    'approved' => t('Одобрены', 'Approved', 'Ma’qullangan'),
    _ => t('Отклонены', 'Rejected', 'Rad etilgan'),
  };
}

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  String _kind = '';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final params = [if (_kind.isNotEmpty) 'kind=$_kind', if (_query.isNotEmpty) 'q=${Uri.encodeQueryComponent(_query)}'];
    return JsonLoader(
      path: '/api/admin/companies${params.isEmpty ? '' : '?${params.join('&')}'}',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        return ScreenScroll(
          key: const Key('admin-companies-frame'),
          children: [
            PageTitle(
              title: t('Компании и банки', 'Companies and banks', 'Kompaniyalar va banklar'),
              subtitle: t('Все организации, допущенные на платформу', 'All organisations admitted to the platform', 'Platformaga qabul qilingan barcha tashkilotlar'),
            ),
            Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [
              FilterChips(
                keyPrefix: 'companies-kind',
                value: _kind,
                onChanged: (value) => setState(() => _kind = value),
                options: [('', t('Все', 'All', 'Hammasi')), ('developer', t('Застройщики', 'Developers', 'Quruvchilar')), ('bank', t('Банки', 'Banks', 'Banklar'))],
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  key: const Key('companies-search'),
                  onSubmitted: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(hintText: t('Название или ИНН, Enter', 'Name or TIN, Enter', 'Nomi yoki STIR, Enter'), prefixIcon: const Icon(Icons.search), isDense: true),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(title: t('Ничего не найдено', 'Nothing found', 'Hech narsa topilmadi'), body: t('Измените фильтр или поиск.', 'Change the filter or the search.', 'Filtr yoki qidiruvni o‘zgartiring.'))
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('companies-list'),
                  children: [
                    TableRowBox(header: true, children: [
                      cellText(context, t('Организация', 'Organisation', 'Tashkilot'), flex: 3, bold: true),
                      cellText(context, t('ИНН', 'TIN', 'STIR'), bold: true),
                      cellText(context, t('Люди', 'People', 'Odamlar'), bold: true),
                      cellText(context, t('Объекты', 'Projects', 'Obyektlar'), bold: true),
                      cellText(context, t('Создана', 'Created', 'Yaratilgan'), bold: true),
                    ]),
                    for (final item in items)
                      TableRowBox(
                        key: Key('company-${item.s('id')}'),
                        onTap: () => context.go('/admin/users?company=${item.s('id')}'),
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(children: [
                              Flexible(child: Text(item.s('name'), style: theme.textTheme.titleSmall)),
                              const SizedBox(width: AppSpacing.sm),
                              Tag(label: item.s('kind') == 'bank' ? t('Банк', 'Bank', 'Bank') : t('Застройщик', 'Developer', 'Quruvchi'), color: item.s('kind') == 'bank' ? colors.success : colors.inkMuted),
                            ]),
                          ),
                          cellText(context, item.s('inn'), muted: true),
                          cellText(context, '${item.i('users_active')} / ${item.i('users')}'),
                          cellText(context, '${item.i('projects')}'),
                          cellText(context, fmtDay(item['created_at']), muted: true),
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

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.company = ''});

  final String company;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';

  Future<void> _toggle(Map<String, dynamic> user, Future<void> Function() reload) async {
    final t = Tx.of(context);
    final turnOff = user.b('active');
    final sure = await showPlainDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(turnOff ? t('Отключить пользователя?', 'Turn the user off?', 'Foydalanuvchini o‘chirasizmi?') : t('Включить пользователя?', 'Turn the user on?', 'Foydalanuvchini yoqasizmi?')),
        content: Text(turnOff
            ? t('${user.s('name')} сразу потеряет доступ, его сессии закроются.', '${user.s('name')} loses access at once and the sessions are closed.', '${user.s('name')} darhol kirish huquqini yo‘qotadi, sessiyalari yopiladi.')
            : t('${user.s('name')} снова сможет войти.', '${user.s('name')} will be able to sign in again.', '${user.s('name')} yana kira oladi.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
          PrimaryButton(key: const Key('user-confirm'), label: turnOff ? t('Отключить', 'Turn off', 'O‘chirish') : t('Включить', 'Turn on', 'Yoqish'), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final api = SessionScope.of(context).api;
    final ok = await runAction(context, () => api.postJson('/api/admin/users/${user.s('id')}/active', {'active': !turnOff}));
    if (ok) await reload();
  }

  Future<void> _reset(Map<String, dynamic> user) async {
    final t = Tx.of(context);
    final api = SessionScope.of(context).api;
    final sure = await showPlainDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Выдать новый пароль?', 'Issue a new password?', 'Yangi parol beraylikmi?')),
        content: Text(t('Старый пароль перестанет работать, сессии ${user.s('name')} закроются. Новый пароль будет показан один раз.',
            'The old password stops working and the sessions of ${user.s('name')} close. The new password is shown once.',
            'Eski parol ishlamay qoladi, ${user.s('name')} sessiyalari yopiladi. Yangi parol bir marta ko‘rsatiladi.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
          PrimaryButton(key: const Key('reset-confirm'), label: t('Выдать', 'Issue', 'Berish'), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    String? password;
    final ok = await runAction(context, () async {
      final answer = await api.postJson('/api/admin/users/${user.s('id')}/reset-password', const {});
      password = answer.s('password');
    });
    if (!ok || password == null || !mounted) return;
    await showPlainDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Новый пароль', 'New password', 'Yangi parol')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${user.s('name')} · ${user.s('login')}'),
          const SizedBox(height: AppSpacing.md),
          SelectableText(password!, key: const Key('new-password'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Text(t('Передайте пароль человеку лично. Закрыв окно, вы его больше не увидите.', 'Hand the password over in person. Once you close this window you will not see it again.', 'Parolni shaxsan topshiring. Oynani yopsangiz, uni boshqa ko‘rmaysiz.'),
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: password!)), child: Text(t('Скопировать', 'Copy', 'Nusxalash'))),
          PrimaryButton(key: const Key('password-close'), label: t('Готово', 'Done', 'Tayyor'), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = [if (widget.company.isNotEmpty) 'company=${widget.company}', if (_query.isNotEmpty) 'q=${Uri.encodeQueryComponent(_query)}'];
    final me = SessionScope.of(context).user;
    return JsonLoader(
      path: '/api/admin/users${params.isEmpty ? '' : '?${params.join('&')}'}',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        return ScreenScroll(
          key: const Key('admin-users-frame'),
          children: [
            PageTitle(
              title: t('Пользователи', 'Users', 'Foydalanuvchilar'),
              subtitle: widget.company.isEmpty
                  ? t('Все учётные записи платформы', 'All accounts of the platform', 'Platformaning barcha hisoblari')
                  : t('Сотрудники выбранной организации', 'People of the chosen organisation', 'Tanlangan tashkilot xodimlari'),
              trailing: widget.company.isEmpty ? null : TextButton(key: const Key('users-all'), onPressed: () => context.go('/admin/users'), child: Text(t('Показать всех', 'Show everyone', 'Hammasini ko‘rsatish'))),
            ),
            SizedBox(
              width: 320,
              child: TextField(
                key: const Key('users-search'),
                onSubmitted: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(hintText: t('Имя, логин или компания, Enter', 'Name, login or company, Enter', 'Ism, login yoki kompaniya, Enter'), prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(title: t('Никого не найдено', 'Nobody found', 'Hech kim topilmadi'), body: t('Измените поиск.', 'Change the search.', 'Qidiruvni o‘zgartiring.'))
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('users-list'),
                  children: [
                    for (final user in items)
                      Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 260,
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(user.s('name'), style: theme.textTheme.titleSmall?.copyWith(color: user.b('active') ? null : colors.inkMuted)),
                                  Text('${user.s('login')} · ${user.s('company')}', style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                                ]),
                              ),
                              SizedBox(
                                width: 220,
                                child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                                  if (user.b('platform_admin')) Tag(label: t('Админ iBuild', 'iBuild admin', 'iBuild admini'), color: colors.danger),
                                  if (user.s('bank_role').isNotEmpty) Tag(label: _bankRole(t, user.s('bank_role')), color: colors.success),
                                  if (!user.b('active')) Tag(label: t('Отключён', 'Turned off', 'O‘chirilgan'), color: colors.inkMuted),
                                ]),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(user.s('last_seen').isEmpty ? t('не входил', 'never signed in', 'kirmagan') : fmtTime(user['last_seen']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                              ),
                              OutlinedButton(
                                key: Key('user-reset-${user.s('id')}'),
                                onPressed: () => _reset(user),
                                child: Text(t('Новый пароль', 'New password', 'Yangi parol')),
                              ),
                              if (user.s('id') != me?.id)
                                OutlinedButton(
                                  key: Key('user-toggle-${user.s('id')}'),
                                  onPressed: () => _toggle(user, reload),
                                  child: Text(user.b('active') ? t('Отключить', 'Turn off', 'O‘chirish') : t('Включить', 'Turn on', 'Yoqish')),
                                ),
                            ],
                          ),
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

String _bankRole(Tx t, String role) {
  return switch (role) {
    'specialist' => t('Банк: специалист', 'Bank: specialist', 'Bank: mutaxassis'),
    'expert' => t('Банк: эксперт', 'Bank: expert', 'Bank: ekspert'),
    'head' => t('Банк: руководитель', 'Bank: head', 'Bank: rahbar'),
    'committee' => t('Банк: комитет', 'Bank: committee', 'Bank: qo‘mita'),
    'risk' => t('Банк: риск', 'Bank: risk', 'Bank: risk'),
    'audit' => t('Банк: аудит', 'Bank: audit', 'Bank: audit'),
    _ => t('Банк: администратор', 'Bank: administrator', 'Bank: administrator'),
  };
}

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _action = '';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final params = [if (_action.isNotEmpty) 'action=$_action', if (_query.isNotEmpty) 'q=${Uri.encodeQueryComponent(_query)}', 'limit=200'];
    return JsonLoader(
      path: '/api/admin/events?${params.join('&')}',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        final actions = (data['actions'] as List? ?? const []).map((a) => '$a').toList();
        return ScreenScroll(
          key: const Key('admin-events-frame'),
          children: [
            PageTitle(
              title: t('Журнал платформы', 'Platform journal', 'Platforma jurnali'),
              subtitle: t('Каждое действие администраторов: решения по заявкам, правки, доступы', 'Every action of the administrators: decisions on applications, changes, access', 'Administratorlarning har bir harakati: arizalar, tahrirlar, kirish huquqlari'),
            ),
            Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('events-action-$_action'),
                  isExpanded: true,
                  initialValue: _action,
                  decoration: InputDecoration(labelText: t('Действие', 'Action', 'Harakat'), isDense: true),
                  items: [DropdownMenuItem(value: '', child: Text(t('Все', 'All', 'Hammasi'))), for (final a in actions) DropdownMenuItem(value: a, child: Text(adminActionName(t, a), overflow: TextOverflow.ellipsis))],
                  onChanged: (value) => setState(() => _action = value ?? ''),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  key: const Key('events-search'),
                  onSubmitted: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(hintText: t('Кто сделал, Enter', 'Who did it, Enter', 'Kim qildi, Enter'), prefixIcon: const Icon(Icons.search), isDense: true),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(title: t('Записей нет', 'No entries', 'Yozuvlar yo‘q'), body: t('Действия администраторов появятся здесь.', 'Actions of administrators will appear here.', 'Administratorlar harakatlari shu yerda ko‘rinadi.'))
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: const Key('events-list'),
                  children: [
                    for (final item in items)
                      TableRowBox(children: [
                        SizedBox(width: 130, child: Text(fmtTime(item['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted))),
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(adminActionName(t, item.s('action'))),
                            if (item.s('target_name').isNotEmpty) Text(item.s('target_name'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                          ]),
                        ),
                        cellText(context, item.s('actor'), flex: 2, muted: true),
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

String _bytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/admin/system',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final db = data.obj('database');
        final server = data.obj('server');
        final migrations = data.obj('migrations');
        final backup = data.obj('backup');
        final tables = data.list('tables');
        final uptime = Duration(seconds: server.i('uptimeSeconds'));
        final backupAt = DateTime.tryParse(backup.s('at'));
        final stale = backupAt == null || DateTime.now().difference(backupAt).inHours > 36;
        return ScreenScroll(
          key: const Key('admin-system-frame'),
          children: [
            PageTitle(
              title: t('Система', 'System', 'Tizim'),
              subtitle: t('Здоровье сервера, базы и резервных копий', 'Health of the server, the database and the backups', 'Server, baza va zaxira nusxalar holati'),
              trailing: OutlinedButton.icon(key: const Key('system-refresh'), onPressed: reload, icon: const Icon(Icons.refresh, size: 18), label: Text(t('Обновить', 'Refresh', 'Yangilash'))),
            ),
            KpiRow(children: [
              Kpi(label: t('База данных', 'Database', 'Ma’lumotlar bazasi'), value: db.b('ok') ? t('Работает', 'Running', 'Ishlayapti') : t('Не отвечает', 'Down', 'Javob bermayapti'), tone: db.b('ok') ? colors.success : colors.danger, hint: '${db.i('latencyMs')} ms · ${db.s('version')}'),
              Kpi(label: t('Размер базы', 'Database size', 'Baza hajmi'), value: _bytes(db.i('sizeBytes'))),
              Kpi(label: t('Миграции', 'Migrations', 'Migratsiyalar'), value: '${migrations.i('n')}', hint: t('последняя ${migrations.s('last')}', 'last ${migrations.s('last')}', 'oxirgisi ${migrations.s('last')}')),
              Kpi(label: t('Сервер работает', 'Server uptime', 'Server ishlash vaqti'), value: uptime.inHours >= 24 ? '${uptime.inDays} ${t('дн.', 'd', 'kun')}' : '${uptime.inHours} ${t('ч', 'h', 'soat')}', hint: '${server.s('environment')} · ${server.s('version')}'),
            ]),
            SectionTitle(t('Резервная копия', 'Backup', 'Zaxira nusxa')),
            IBuildCard(
              key: const Key('system-backup'),
              child: backup.isEmpty
                  ? Text(
                      t('Сервер не видит папку с копиями. Проверьте, что она подключена (переменная BACKUP_DIR) и что расписание копий установлено.',
                          'The server cannot see the backup folder. Check that it is mounted (BACKUP_DIR) and that the backup schedule is installed.',
                          'Server zaxira papkasini ko‘rmayapti. U ulanganini (BACKUP_DIR) va nusxa jadvali o‘rnatilganini tekshiring.'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: colors.danger),
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Tag(label: stale ? t('Устарела', 'Stale', 'Eskirgan') : t('Свежая', 'Fresh', 'Yangi'), color: stale ? colors.danger : colors.success),
                        const SizedBox(width: AppSpacing.md),
                        Text(fmtTime(backup['at']), style: theme.textTheme.titleSmall),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${backup.s('file')} · ${_bytes(backup.i('sizeBytes'))}', style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                    ]),
            ),
            SectionTitle(t('Самые большие таблицы', 'The biggest tables', 'Eng katta jadvallar')),
            IBuildCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final table in tables)
                  TableRowBox(children: [cellText(context, table.s('name'), flex: 3), cellText(context, '${table.i('rows')}', align: TextAlign.end, muted: true)]),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class AdminMailScreen extends StatefulWidget {
  const AdminMailScreen({super.key});

  @override
  State<AdminMailScreen> createState() => _AdminMailScreenState();
}

class _AdminMailScreenState extends State<AdminMailScreen> {
  final _to = TextEditingController();
  int _version = 0;

  @override
  void dispose() {
    _to.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final t = Tx.of(context);
    final api = SessionScope.of(context).api;
    final messenger = ScaffoldMessenger.of(context);
    var mail = '';
    final ok = await runAction(context, () async {
      final answer = await api.postJson('/api/admin/mail/test', {'to': _to.text.trim()});
      mail = answer.s('mail');
    });
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(mailResultText(t, mail, t('Тестовое письмо', 'The test letter', 'Sinov xati')))));
    setState(() => _version++);
  }

  Future<void> _retry(String id) async {
    final api = SessionScope.of(context).api;
    final ok = await runAction(context, () => api.postJson('/api/admin/mail/$id/retry', {}));
    if (ok && mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      key: ValueKey('mail-$_version'),
      path: '/api/admin/mail',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final connected = data.b('connected');
        final counts = data.obj('counts');
        final items = data.list('items');
        return ScreenScroll(
          key: const Key('admin-mail-frame'),
          children: [
            PageTitle(
              title: t('Почта', 'Mail', 'Pochta'),
              subtitle: t('Все письма платформы: напоминания банка и отчёты по расписанию', 'Every letter of the platform: bank reminders and scheduled reports', 'Platformaning barcha xatlari: bank eslatmalari va jadval bo‘yicha hisobotlar'),
            ),
            IBuildCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(connected ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: connected ? colors.success : colors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      key: const Key('mail-state'),
                      connected
                          ? t('Почта подключена: отправитель ${data.s('from')}', 'Mail is connected: sender ${data.s('from')}', 'Pochta ulangan: yuboruvchi ${data.s('from')}')
                          : t('Почта не подключена: письма ждут в очереди. Задайте SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM и перезапустите сервер.', 'Mail is not connected: letters wait in the queue. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM and restart the server.', 'Pochta ulanmagan: xatlar navbatda. SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM ni sozlab, serverni qayta ishga tushiring.'),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                Wrap(spacing: AppSpacing.lg, children: [
                  Text(t('Отправлено: ${counts.i('sent')}', 'Sent: ${counts.i('sent')}', 'Yuborilgan: ${counts.i('sent')}')),
                  Text(t('В очереди: ${counts.i('queued')}', 'Queued: ${counts.i('queued')}', 'Navbatda: ${counts.i('queued')}')),
                  Text(t('С ошибкой: ${counts.i('failed')}', 'Failed: ${counts.i('failed')}', 'Xatolik: ${counts.i('failed')}')),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  SizedBox(
                    width: 280,
                    child: TextField(key: const Key('mail-test-to'), controller: _to, decoration: InputDecoration(labelText: t('Адрес для проверки', 'Address to test', 'Tekshirish manzili'), isDense: true)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton(key: const Key('mail-test'), onPressed: _test, child: Text(t('Отправить тест', 'Send a test', 'Sinov yuborish'))),
                ]),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(title: t('Писем нет', 'No letters', 'Xatlar yo‘q'), body: t('Напоминания и отчёты банка появятся здесь.', 'Bank reminders and reports will appear here.', 'Bank eslatmalari va hisobotlari shu yerda ko‘rinadi.'))
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(key: const Key('mail-list'), children: [
                  for (final item in items)
                    TableRowBox(children: [
                      SizedBox(width: 130, child: Text(fmtTime(item['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted))),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.s('subject'), overflow: TextOverflow.ellipsis),
                          Text(item.s('to') + (item.s('bank').isEmpty ? '' : ' · ${item.s('bank')}'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                          if (item.s('error').isNotEmpty) Text(item.s('error'), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colors.danger)),
                        ]),
                      ),
                      Tag(
                        label: switch (item.s('status')) {
                          'sent' => t('Отправлено', 'Sent', 'Yuborildi'),
                          'failed' => t('Ошибка', 'Failed', 'Xatolik'),
                          _ => t('В очереди', 'Queued', 'Navbatda'),
                        },
                        color: item.s('status') == 'sent' ? colors.success : item.s('status') == 'failed' ? colors.danger : colors.warning,
                      ),
                      if (item.s('status') != 'sent' && item.s('attachment').isEmpty && connected)
                        TextButton(key: Key('mail-retry-${item.s('id')}'), onPressed: () => _retry(item.s('id')), child: Text(t('Повторить', 'Retry', 'Qayta'))),
                    ]),
                ]),
              ),
          ],
        );
      },
    );
  }
}
