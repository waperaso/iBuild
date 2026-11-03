import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../theme.dart';
import '../widgets.dart';
import 'kit.dart';

/// The mailbox of the signed-in person: letters inside iBuild, kept sealed on
/// the server. Three states: the list of a folder, one conversation, a new letter.
class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

enum _Mode { list, thread, compose }

class _MailScreenState extends State<MailScreen> {
  _Mode _mode = _Mode.list;
  String _folder = 'inbox';
  String? _openId;
  Map<String, dynamic>? _replyTo;
  int _generation = 0;

  void _show(_Mode mode, {String? id, Map<String, dynamic>? reply}) {
    setState(() {
      _mode = mode;
      _openId = id;
      _replyTo = reply;
      _generation++;
    });
    SessionScope.of(context).refreshMail(force: true);
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.list:
        return _MailList(
          key: ValueKey('list-$_folder-$_generation'),
          folder: _folder,
          onFolder: (folder) => setState(() {
            _folder = folder;
            _generation++;
          }),
          onOpen: (id) => _show(_Mode.thread, id: id),
          onCompose: () => _show(_Mode.compose),
        );
      case _Mode.thread:
        return _MailThread(
          key: ValueKey('thread-$_openId-$_generation'),
          id: _openId!,
          onBack: () => _show(_Mode.list),
          onReply: (thread) => _show(_Mode.compose, reply: thread),
        );
      case _Mode.compose:
        return _MailCompose(
          key: ValueKey('compose-$_generation'),
          reply: _replyTo,
          onDone: () => _show(_Mode.list),
          onCancel: () => _show(_replyTo == null ? _Mode.list : _Mode.thread, id: _replyTo?['id'] as String?),
        );
    }
  }
}

class _MailList extends StatelessWidget {
  const _MailList({super.key, required this.folder, required this.onFolder, required this.onOpen, required this.onCompose});

  final String folder;
  final ValueChanged<String> onFolder;
  final ValueChanged<String> onOpen;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/mail/messages?folder=$folder',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final items = data.list('items');
        final sent = folder == 'sent';
        return ScreenScroll(
          key: const Key('mail-frame'),
          children: [
            PageTitle(
              title: t('Почта', 'Mail', 'Pochta'),
              subtitle: t('Письма внутри iBuild. На сервере тема и текст хранятся в зашифрованном виде.', 'Letters inside iBuild. Subject and text are stored encrypted on the server.', 'iBuild ichidagi xatlar. Mavzu va matn serverda shifrlangan holda saqlanadi.'),
              trailing: PrimaryButton(key: const Key('mail-compose'), label: t('Написать', 'Write', 'Yozish'), onPressed: onCompose),
            ),
            Wrap(spacing: AppSpacing.sm, children: [
              ChoiceChip(key: const Key('mail-inbox'), label: Text(t('Входящие', 'Inbox', 'Kiruvchi')), selected: !sent, onSelected: (_) => onFolder('inbox')),
              ChoiceChip(key: const Key('mail-sent'), label: Text(t('Отправленные', 'Sent', 'Yuborilgan')), selected: sent, onSelected: (_) => onFolder('sent')),
            ]),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              EmptyState(
                title: sent ? t('Вы пока ничего не отправляли', 'You have not sent anything yet', 'Siz hali hech narsa yubormagansiz') : t('Писем нет', 'No letters', 'Xatlar yo‘q'),
                body: t('Нажмите «Написать», чтобы начать переписку.', 'Press “Write” to start a conversation.', 'Yozishni boshlash uchun «Yozish» tugmasini bosing.'),
              )
            else
              IBuildCard(
                padding: EdgeInsets.zero,
                child: Column(key: const Key('mail-list'), children: [
                  for (final item in items)
                    Column(children: [
                      InkWell(
                        key: Key('mail-item-${item.s('id')}'),
                        onTap: () => onOpen(item.s('id')),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(children: [
                            SizedBox(
                              width: 12,
                              child: item.b('unread') ? Icon(Icons.circle, size: 10, color: colors.accent, key: Key('mail-unread-${item.s('id')}')) : null,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(width: 200, child: Text((sent ? '${t('Кому', 'To', 'Kimga')}: ' : '') + item.s('people'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: item.b('unread') ? FontWeight.w700 : FontWeight.w500))),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(item.s('subject'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: item.b('unread') ? FontWeight.w700 : FontWeight.w400))),
                            const SizedBox(width: AppSpacing.md),
                            Text(fmtTime(item['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                          ]),
                        ),
                      ),
                      Divider(height: 1, color: colors.outline),
                    ]),
                ]),
              ),
          ],
        );
      },
    );
  }
}

class _MailThread extends StatelessWidget {
  const _MailThread({super.key, required this.id, required this.onBack, required this.onReply});

  final String id;
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onReply;

  Future<void> _delete(BuildContext context) async {
    final api = SessionScope.of(context).api;
    final ok = await runAction(context, () => api.postJson('/api/mail/messages/$id/delete', const {}));
    if (ok) onBack();
  }

  @override
  Widget build(BuildContext context) {
    return JsonLoader(
      path: '/api/mail/messages/$id',
      builder: (context, data, reload) {
        final t = Tx.of(context);
        final theme = Theme.of(context);
        final colors = context.colors;
        final messages = data.list('messages');
        return ScreenScroll(
          key: const Key('mail-thread'),
          children: [
            PageTitle(
              title: data.s('subject'),
              subtitle: t('Переписка', 'Conversation', 'Yozishma'),
              trailing: TextButton(key: const Key('mail-back'), onPressed: onBack, child: Text(t('К списку', 'Back to the list', 'Ro‘yxatga'))),
            ),
            for (final message in messages) ...[
              IBuildCard(
                key: Key('mail-message-${message.s('id')}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${message.b('mine') ? t('Вы', 'You', 'Siz') : message.s('sender')} → ${message.b('mine') ? message.s('people') : t('вам', 'you', 'sizga')}', style: theme.textTheme.titleSmall),
                  Text(fmtTime(message['at']), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted)),
                  const SizedBox(height: AppSpacing.md),
                  SelectableText(message.s('body')),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(children: [
              PrimaryButton(key: const Key('mail-reply'), label: t('Ответить', 'Reply', 'Javob yozish'), onPressed: () => onReply(data)),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(key: const Key('mail-delete'), onPressed: () => _delete(context), child: Text(t('Удалить', 'Delete', 'O‘chirish'))),
            ]),
          ],
        );
      },
    );
  }
}

class _MailCompose extends StatefulWidget {
  const _MailCompose({super.key, required this.reply, required this.onDone, required this.onCancel});

  final Map<String, dynamic>? reply;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<_MailCompose> createState() => _MailComposeState();
}

class _MailComposeState extends State<_MailCompose> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _chosen = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final reply = widget.reply;
    if (reply != null) {
      final subject = (reply['subject'] as String?) ?? '';
      _subject.text = subject.startsWith('Re: ') ? subject : 'Re: $subject';
      final messages = (reply['messages'] as List?) ?? const [];
      for (final message in messages) {
        if (message is Map && message['mine'] != true && message['sender_id'] is String) {
          _chosen.add(message['sender_id'] as String);
        }
      }
      if (_chosen.isEmpty) {
        // The last letter is mine: write again to the same people.
        for (final message in messages) {
          if (message is Map && message['recipient_ids'] is List) {
            _chosen.addAll((message['recipient_ids'] as List).cast<String>());
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = Tx.of(context);
    final api = SessionScope.of(context).api;
    if (_chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Выберите получателя.', 'Choose a recipient.', 'Qabul qiluvchini tanlang.'))));
      return;
    }
    setState(() => _busy = true);
    final ok = await runAction(context, () => api.postJson('/api/mail/messages', {
          'to': _chosen.toList(),
          'subject': _subject.text.trim(),
          'body': _body.text.trim(),
          if (widget.reply != null) 'threadId': widget.reply!['threadId'],
        }));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = Tx.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    return JsonLoader(
      path: '/api/mail/contacts',
      builder: (context, data, reload) {
        final contacts = data.list('items');
        return ScreenScroll(
          key: const Key('mail-compose-frame'),
          children: [
            PageTitle(
              title: widget.reply == null ? t('Новое письмо', 'New letter', 'Yangi xat') : t('Ответ', 'Reply', 'Javob'),
              subtitle: t('Писать можно коллегам, администратору iBuild и партнёрам по объектам.', 'You can write to colleagues, the iBuild administrator and partners on projects.', 'Hamkasblar, iBuild administratori va obyektlar bo‘yicha hamkorlarga yozish mumkin.'),
            ),
            IBuildCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('Кому', 'To', 'Kimga'), style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                if (contacts.isEmpty && _chosen.isEmpty)
                  Text(t('Пока некому писать.', 'There is nobody to write to yet.', 'Hozircha yozadigan odam yo‘q.'), style: theme.textTheme.bodySmall?.copyWith(color: colors.inkMuted))
                else
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                    for (final person in contacts)
                      FilterChip(
                        key: Key('mail-to-${person.s('id')}'),
                        label: Text('${person.s('name')} · ${person.s('title').isEmpty ? person.s('company') : person.s('title')}'),
                        selected: _chosen.contains(person.s('id')),
                        onSelected: (on) => setState(() => on ? _chosen.add(person.s('id')) : _chosen.remove(person.s('id'))),
                      ),
                  ]),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('mail-subject'),
                  controller: _subject,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: t('Тема', 'Subject', 'Mavzu')),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('mail-body'),
                  controller: _body,
                  minLines: 6,
                  maxLines: 14,
                  maxLength: 10000,
                  decoration: InputDecoration(labelText: t('Текст письма', 'Text of the letter', 'Xat matni'), alignLabelWithHint: true),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  PrimaryButton(key: const Key('mail-send'), label: t('Отправить', 'Send', 'Yuborish'), busy: _busy, onPressed: _busy ? null : _send),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(key: const Key('mail-cancel'), onPressed: widget.onCancel, child: Text(t('Отмена', 'Cancel', 'Bekor qilish'))),
                ]),
              ]),
            ),
          ],
        );
      },
    );
  }
}
