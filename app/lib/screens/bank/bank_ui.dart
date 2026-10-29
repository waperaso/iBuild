import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../l10n.dart';
import '../../money.dart';
import '../../theme.dart';
import 'bank_models.dart';

/// Amounts in the bank cabinet are millions of UZS, or whole dollars when the
/// USD switch is on and the central bank rate is known.
bool bankShowsUsd(BuildContext context) {
  final fx = FxScope.maybeOf(context);
  final rate = fx?.rate;
  return fx != null && fx.usd && rate != null && moneyCents(rate) > BigInt.zero;
}

String bankAmount(BuildContext context, Object? raw) {
  if (!bankShowsUsd(context)) return moneyMillions(raw);
  // Both the amount and the rate are in hundredths, so scale by 100 to get dollar cents.
  final rate = moneyCents(FxScope.maybeOf(context)!.rate);
  final dollarCents = moneyCents(raw) * BigInt.from(100) ~/ rate;
  final dollars = (dollarCents + BigInt.from(50)) ~/ BigInt.from(100);
  return moneyAsShown(dollars.toString()).replaceAll('\u00a0', ' ');
}

String bankUnit(BuildContext context) {
  return bankShowsUsd(context) ? 'USD' : LocaleScope.copy(context).millionUzs;
}

bool bankPositive(Object? raw) => moneyCents(raw) > BigInt.zero;

const _blueLight = Color(0xFF2D6CDF);
const _blueDark = Color(0xFF7EB6E6);

Color bankBlue(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark ? _blueDark : _blueLight;
}

/// The row dot. Red is a missed bank deadline, yellow is a block or a warning,
/// blue is a tranche waiting for the expert, grey is a tranche at the developer.
Color bankSignalColor(BuildContext context, {required String signal, required bool overdue}) {
  final colors = context.colors;
  if (overdue) return colors.danger;
  return switch (signal) {
    'block' || 'warning' => colors.warning,
    'inspection' => bankBlue(context),
    'developer' => colors.inkMuted.withValues(alpha: 0.55),
    _ => colors.success,
  };
}

Color bankLevelColor(BuildContext context, String level) {
  final colors = context.colors;
  return switch (level) {
    'block' => colors.danger,
    'warning' => colors.warning,
    'signal' => bankBlue(context),
    'reminder' => colors.inkMuted,
    _ => colors.success,
  };
}

class BankDot extends StatelessWidget {
  const BankDot({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(width: size, height: size),
    );
  }
}

class BankPill extends StatelessWidget {
  const BankPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}

/// The six stages of a tranche as a strip: done, current, pending.
class BankStageStrip extends StatelessWidget {
  const BankStageStrip({super.key, required this.stages});

  final List<BankStage> stages;

  @override
  Widget build(BuildContext context) {
    final strings = BankStrings.of(context);
    final colors = context.colors;
    return Row(
      key: const Key('bank-stage-strip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in stages)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    key: Key('bank-stage-${stage.code}'),
                    decoration: BoxDecoration(
                      color: switch (stage.state) {
                        'done' => colors.success,
                        'current' => bankBlue(context),
                        _ => colors.outline,
                      },
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const SizedBox(height: 6, width: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings.stage(stage.code),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: stage.state == 'pending' ? colors.inkMuted : colors.ink,
                      fontWeight: stage.state == 'current' ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Texts of the bank cabinet in the three interface languages.
class BankStrings {
  const BankStrings(this.language);

  factory BankStrings.of(BuildContext context) {
    return BankStrings(LocaleScope.copy(context).language);
  }

  final AppLanguage language;

  String _t(String ru, String en, String uz) {
    return switch (language) {
      AppLanguage.en => en,
      AppLanguage.uz => uz,
      AppLanguage.ru => ru,
    };
  }

  // Queue.
  String tab(String code) {
    return switch (code) {
      'all' => _t('Все в работе', 'All in progress', 'Barchasi ishda'),
      'developer' => _t('У застройщика', 'With the developer', 'Quruvchida'),
      'overdue' => _t('Просрочены', 'Overdue', 'Muddati o‘tgan'),
      _ => _t('Мои', 'Mine', 'Meniki'),
    };
  }

  String get amountsIn => _t('Суммы в', 'Amounts in', 'Summalar:');
  String get colObject => _t('Объект', 'Project', 'Obyekt');
  String get colTranche => _t('Транш', 'Tranche', 'Transh');
  String get colAmount => _t('Сумма', 'Amount', 'Summa');
  String get colStage => _t('Этап', 'Step', 'Bosqich');
  String get colTime => _t('Срок', 'Time', 'Muddat');
  String get colProblems => _t('Замечания', 'Findings', 'Izohlar');
  String get colHolder => _t('У кого', 'With whom', 'Kimda');
  String get open => _t('Открыть', 'Open', 'Ochish');
  String trancheNo(int no) => _t('№$no', '#$no', '№$no');
  String get retry => _t('Повторить', 'Try again', 'Qayta urinish');
  String get loadFailed => _t(
    'Не получилось загрузить данные. Попробуйте ещё раз.',
    'Could not load the data. Please try again.',
    'Ma’lumotlarni yuklab bo‘lmadi. Qayta urinib ko‘ring.',
  );
  String get notFound => _t('Транш не найден', 'Tranche not found', 'Transh topilmadi');

  String emptyTitle(String tab) {
    return switch (tab) {
      'all' => _t('Очередь пуста', 'The queue is empty', 'Navbat bo‘sh'),
      'developer' => _t('Никто не ждёт застройщика', 'Nobody is waiting for a developer', 'Quruvchini hech kim kutmayapti'),
      'overdue' => _t('Просроченных траншей нет', 'No overdue tranches', 'Muddati o‘tgan transh yo‘q'),
      _ => _t('За вами пока нет траншей', 'No tranches assigned to you yet', 'Sizga hali transh biriktirilmagan'),
    };
  }

  String emptyBody(String tab) {
    return switch (tab) {
      'all' => _t('Когда застройщик отправит транш, он появится здесь.', 'When a developer sends a tranche, it shows up here.', 'Quruvchi transh yuborganda, u shu yerda paydo bo‘ladi.'),
      'developer' => _t('Все транши сейчас у банка.', 'All tranches are with the bank right now.', 'Hozir barcha transhlar bankda.'),
      'overdue' => _t('Банк успевает вовремя по всем траншам.', 'The bank is on time with every tranche.', 'Bank barcha transhlar bo‘yicha o‘z vaqtida.'),
      _ => _t('Чтобы увидеть остальные транши, откройте «Все в работе».', 'To see the other tranches, open “All in progress”.', 'Qolgan transhlarni ko‘rish uchun “Barchasi ishda” bo‘limini oching.'),
    };
  }

  String get legendOverdue => _t('банк не уложился в срок', 'the bank missed its deadline', 'bank muddatga ulgurmadi');
  String get legendProblem => _t('есть замечание', 'has a finding', 'izoh bor');
  String get legendInspection => _t('ждёт осмотра', 'waiting for an inspection', 'ko‘rikni kutmoqda');
  String get legendDeveloper => _t('у застройщика', 'with the developer', 'quruvchida');

  String elapsed(BankQueueItem item) => elapsedLabel(
    waitingDeveloper: item.waitingDeveloper,
    days: item.elapsedDays,
    hours: item.elapsedHours,
    sla: item.slaDays,
  );

  String elapsedLabel({
    required bool waitingDeveloper,
    required int days,
    required int hours,
    required int sla,
  }) {
    final d = _t('дн.', 'd', 'kun');
    final h = _t('ч', 'h', 'soat');
    if (waitingDeveloper) {
      return _t('$days $d у застройщика', '$days $d with the developer', '$days $d quruvchida');
    }
    final spent = hours == 0
        ? '$days $d'
        : days == 0
            ? '$hours $h'
            : '$days $d $hours $h';
    return _t('Прошло $spent · срок банка $sla $d', '$spent passed · bank deadline $sla $d', '$spent o‘tdi · bank muddati $sla $d');
  }

  // Tranche card.
  String get backToQueue => _t('К очереди', 'Back to the queue', 'Navbatga qaytish');
  String tranche(int no) => _t('Транш №$no', 'Tranche #$no', 'Transh №$no');
  String get limitIssued => _t('Лимит и выплаты', 'Limit and payouts', 'Limit va to‘lovlar');
  String submitted(String date, String time) =>
      _t('Подан $date в $time', 'Sent $date at $time', 'Yuborilgan: $date, $time');
  String techConfirmed(String date) =>
      _t('технадзор проверил $date', 'supervisor checked $date', 'texnazorat $date tekshirdi');
  String rules(int version) =>
      _t('правила банка, версия $version', 'bank rules, version $version', 'bank qoidalari, $version-versiya');

  String stage(String code) {
    return switch (code) {
      'submitted' => _t('Подан', 'Sent', 'Yuborilgan'),
      'docs' => _t('Проверка документов', 'Document check', 'Hujjatlarni tekshirish'),
      'inspection' => _t('Осмотр', 'Inspection', 'Ko‘rik'),
      'specialist' => _t('Решение специалиста', 'Specialist’s decision', 'Mutaxassis qarori'),
      'approval' => _t('Согласование', 'Sign-off', 'Kelishuv'),
      'payout' => _t('Выплата', 'Payout', 'To‘lov'),
      _ => code,
    };
  }

  String get sumRequested => _t('Запрошено', 'Requested', 'So‘ralgan');
  String get sumConfirmed => _t('Подтвердил эксперт', 'Confirmed by the expert', 'Ekspert tasdiqlagan');
  String get sumBlocked => _t('Задержано', 'On hold', 'To‘xtatilgan');
  String get sumIssue => _t('К выплате', 'To pay out', 'To‘lash uchun');
  String get sumRemaining => _t('Останется в лимите', 'Left in the limit', 'Limitda qoladi');

  String get checksTitle => _t('На что обратить внимание', 'What needs attention', 'Nimaga e’tibor berish kerak');
  String get checksSubtitle => _t(
    'Транш проверен автоматически по правилам банка',
    'The tranche was checked automatically against the bank’s rules',
    'Transh bank qoidalari bo‘yicha avtomatik tekshirildi',
  );
  String get noOpenChecks => _t('Замечаний нет. Всё в порядке.', 'No findings. Everything is fine.', 'Izoh yo‘q. Hammasi joyida.');
  String showPassed(int count) => _t('Показать, что в порядке ($count)', 'Show what is fine ($count)', 'Joyidagilarini ko‘rsatish ($count)');
  // Journal.
  String get journalTitle => _t('Журнал изменений', 'Change journal', 'O‘zgarishlar jurnali');
  String get journalShow => _t('Показать журнал', 'Show the journal', 'Jurnalni ko‘rsatish');
  String get journalHide => _t('Скрыть журнал', 'Hide the journal', 'Jurnalni yashirish');
  String get journalEmpty => _t('Записей пока нет', 'No entries yet', 'Hozircha yozuvlar yo‘q');
  String get journalFailed => _t('Не удалось загрузить журнал', 'Could not load the journal', 'Jurnalni yuklab bo‘lmadi');

  String _choiceName(Object? code) => switch (code) {
        'requested' => _t('запрошенная', 'requested', 'so‘ralgan'),
        'withhold' => _t('не выдавать', 'withhold', 'bermaslik'),
        _ => _t('подтверждённая', 'confirmed', 'tasdiqlangan'),
      };

  String _checkName(Object? code) => switch (code) {
        'certificate' => _t('нет документов на материалы', 'no documents for materials', 'materiallar hujjatlari yo‘q'),
        'above_confirmed' => _t('запрошено больше подтверждённого', 'asked above confirmed', 'tasdiqlangandan ko‘p so‘ralgan'),
        'subcontractor' => _t('документы подрядчика', 'contractor documents', 'pudratchi hujjatlari'),
        'payable_waiver' => _t('отказ от претензий', 'waiver of claims', 'da’volardan voz kechish'),
        'limit' => _t('остаток лимита', 'limit left', 'limit qoldig‘i'),
        'forecast' => _t('срок завершения', 'completion date', 'tugash muddati'),
        _ => '${code ?? ''}',
      };

  String _decisionName(Object? code) => switch (code) {
        'return_all' => _t('вернуть транш целиком', 'return the whole tranche', 'transhni to‘liq qaytarish'),
        'control_measure' => _t('контрольный замер', 'control measurement', 'nazorat o‘lchovi'),
        'suspend' => _t('приостановить финансирование', 'suspend financing', 'moliyalashni to‘xtatish'),
        _ => _t('выдать часть', 'issue a part', 'bir qismini berish'),
      };

  String _voteName(Object? code) => switch (code) {
        'return' => _t('вернуть', 'return', 'qaytarish'),
        'reject' => _t('отказать', 'reject', 'rad etish'),
        _ => _t('согласовать', 'approve', 'kelishish'),
      };

  /// One readable line for the journal. The facts are the ones the server wrote.
  String journalLine(BankJournalEntry entry) {
    final d = entry.detail;
    switch (entry.action) {
      case 'tranche_created':
        return _t('Транш поступил в банк', 'The tranche reached the bank', 'Transh bankka tushdi');
      case 'inspection_reported':
        return _t('Эксперт сдал осмотр, транш у специалиста', 'The expert reported, the tranche is with the specialist', 'Ekspert ko‘rikni topshirdi, transh mutaxassisda');
      case 'choose':
        return _t(
          'Статья «${d['line']}»: ${_choiceName(d['from'])} → ${_choiceName(d['to'])}',
          'Line “${d['line']}”: ${_choiceName(d['from'])} → ${_choiceName(d['to'])}',
          '“${d['line']}” moddasi: ${_choiceName(d['from'])} → ${_choiceName(d['to'])}',
        );
      case 'waive':
        final comment = '${d['comment'] ?? ''}'.trim();
        return _t(
          'Проверка принята с обоснованием: ${_checkName(d['check'])}${comment.isEmpty ? '' : '. $comment'}',
          'Check accepted with a reason: ${_checkName(d['check'])}${comment.isEmpty ? '' : '. $comment'}',
          'Tekshiruv asos bilan qabul qilindi: ${_checkName(d['check'])}${comment.isEmpty ? '' : '. $comment'}',
        );
      case 'request':
        return _t('Запрос застройщику: ${_checkName(d['check'])}', 'Request to the developer: ${_checkName(d['check'])}', 'Quruvchiga so‘rov: ${_checkName(d['check'])}');
      case 'resume':
        return _t('Транш снова у банка', 'The tranche is back at the bank', 'Transh yana bankda');
      case 'decision':
        return _t('Решение: ${_decisionName(d['kind'])}', 'Decision: ${_decisionName(d['kind'])}', 'Qaror: ${_decisionName(d['kind'])}');
      case 'vote':
        final comment = '${d['comment'] ?? ''}'.trim();
        return _t(
          'Голос: ${_voteName(d['vote'])}${comment.isEmpty ? '' : '. $comment'}',
          'Vote: ${_voteName(d['vote'])}${comment.isEmpty ? '' : '. $comment'}',
          'Ovoz: ${_voteName(d['vote'])}${comment.isEmpty ? '' : '. $comment'}',
        );
      default:
        return entry.action;
    }
  }

  String get hidePassed => _t('Скрыть то, что в порядке', 'Hide what is fine', 'Joyidagilarini yashirish');

  String action(String code) {
    return switch (code) {
      'request_document' => _t('Запросить документ', 'Ask for a document', 'Hujjat so‘rash'),
      'request_schedule' => _t('Запросить график работ', 'Ask for a work schedule', 'Ish jadvalini so‘rash'),
      'waive' => _t('Принять с обоснованием', 'Accept with a reason', 'Asos bilan qabul qilish'),
      _ => code,
    };
  }

  String get linesTitle => _t('Виды работ в этом транше', 'Work items in this tranche', 'Ushbu transhdagi ish turlari');
  String get colLine => _t('Вид работ', 'Work item', 'Ish turi');
  String get colIssuedBefore => _t('Выплачено раньше', 'Paid before', 'Avval to‘langan');
  String get colRequested => _t('Запрошено', 'Requested', 'So‘ralgan');
  String get colReadiness => _t('Готовность', 'Progress', 'Tayyorlik');
  String get colConfirmed => _t('Подтверждено', 'Confirmed', 'Tasdiqlangan');
  String get colToIssue => _t('К выплате', 'To pay out', 'To‘lash uchun');
  String get total => _t('Итого', 'Total', 'Jami');

  String get decisionNote => _t(
    'Специалист готовит решение, но деньги сам не выплачивает: решение идёт дальше на согласование.',
    'The specialist prepares the decision but does not pay out the money: the decision goes on for sign-off.',
    'Mutaxassis qarorni tayyorlaydi, lekin pulni o‘zi to‘lamaydi: qaror kelishuvga o‘tadi.',
  );
  String approveAndReturn(String issue, String returned) => _t(
    'Одобрить $issue, а $returned вернуть на доработку',
    'Approve $issue and send $returned back for rework',
    '$issue ni ma’qullash, $returned ni qayta ishlashga qaytarish',
  );
  String approveOnly(String issue) => _t('Одобрить $issue', 'Approve $issue', '$issue ni ma’qullash');
  String get returnAll => _t('Вернуть застройщику целиком', 'Send it all back to the developer', 'Hammasini quruvchiga qaytarish');
  String get orderInspection => _t('Заказать проверку на месте', 'Order a check on site', 'Joyida tekshiruvni buyurtma qilish');
  String get suspend => _t('Приостановить финансирование', 'Pause the financing', 'Moliyalashtirishni to‘xtatish');

  // Line evidence.
  String get colDetails => _t('Подробнее', 'Details', 'Batafsil');
  String expertInspection(String name, String date) => _t(
    'Осмотр эксперта: $name, $date, подписано',
    'Expert inspection: $name, $date, signed',
    'Ekspert ko‘rigi: $name, $date, imzolangan',
  );
  String readinessWas(String percent, String previous) => _t(
    'Готовность $percent% (было $previous%)',
    'Progress $percent% (was $previous%)',
    'Tayyorlik $percent% (avval $previous%)',
  );
  String get remainingToBuild => _t('Осталось построить', 'Left to build', 'Qurish qoldi');
  String get recommends => _t('Эксперт рекомендует выдать', 'The expert recommends paying', 'Ekspert to‘lashni tavsiya qiladi');
  String get riskFlag => _t('Признак риска', 'Risk flag', 'Xavf belgisi');
  String get yes => _t('да', 'yes', 'ha');
  String get no => _t('нет', 'no', 'yo‘q');
  String get noExpertEvidence => _t(
    'Осмотра по этой статье нет. Сумма взята из акта и документов.',
    'There is no inspection for this item. The amount comes from the act and the documents.',
    'Bu modda ko‘rik yo‘q. Summa dalolatnoma va hujjatlardan olingan.',
  );
  String get photosTitle => _t('Фото с объекта', 'Photos from the site', 'Obyektdan suratlar');
  String get documentsTitle => _t('Документы', 'Documents', 'Hujjatlar');
  String get documentMissing => _t('не предъявлен', 'not provided', 'taqdim etilmagan');
  String get howCounted => _t('Как посчитано', 'How it was counted', 'Qanday hisoblangan');
  String formula({
    required String percent,
    required String plan,
    required String gross,
    required String before,
    required String result,
  }) => _t(
    '$percent% × $plan = $gross − выдано ранее $before = $result',
    '$percent% × $plan = $gross − paid before $before = $result',
    '$percent% × $plan = $gross − avval to‘langan $before = $result',
  );
  String get paymentsTitle => _t('Выплаты по статье', 'Payouts for this item', 'Modda bo‘yicha to‘lovlar');
  String get choiceTitle => _t('Что выплатить по статье', 'What to pay for this item', 'Modda bo‘yicha nima to‘lanadi');
  String choiceLabel(String code) {
    return switch (code) {
      'requested' => _t('Запрошенное', 'Requested', 'So‘ralgan'),
      'withhold' => _t('Не выдавать', 'Do not pay', 'To‘lamaslik'),
      _ => _t('Подтверждённое', 'Confirmed', 'Tasdiqlangan'),
    };
  }

  String get choiceAboveConfirmed => _t(
    'Выдать больше подтверждённого нельзя: «Запрошенное» недоступно, пока запрос выше суммы, которую подтвердил эксперт.',
    'Paying more than confirmed is not allowed: “Requested” is off while the request is above what the expert confirmed.',
    'Tasdiqlanganidan ko‘p to‘lash mumkin emas: so‘rov ekspert tasdiqlagandan yuqori bo‘lsa, “So‘ralgan” o‘chiq.',
  );
  String get lineBlockedNote => _t(
    'Статья остановлена проверкой. Примите проверку с обоснованием или не выдавайте.',
    'The item is stopped by a check. Accept the check with a reason or do not pay.',
    'Modda tekshiruv bilan to‘xtatilgan. Tekshiruvni asos bilan qabul qiling yoki to‘lamang.',
  );

  // Checks.
  String requestedStamp(String kind, String at) => kind == 'schedule'
      ? _t('Запрос графика отправлен $at', 'Schedule requested $at', 'Jadval so‘raldi: $at')
      : _t('Запрос документа отправлен $at', 'Document requested $at', 'Hujjat so‘raldi: $at');
  String waivedStamp(String by, String at, String reason) => _t(
    'Принято с обоснованием: $reason · $by, $at',
    'Accepted with a reason: $reason · $by, $at',
    'Asos bilan qabul qilingan: $reason · $by, $at',
  );
  String waiveReason(String code) {
    return switch (code) {
      'outside_system' => _t('Документ получен вне системы', 'The document was received outside the system', 'Hujjat tizimdan tashqarida olingan'),
      'fixed_elsewhere' => _t('Исправлено в другой части заявки', 'Fixed in another part of the request', 'Arizaning boshqa qismida tuzatilgan'),
      'approved_exception' => _t('Утверждённое исключение', 'Approved exception', 'Tasdiqlangan istisno'),
      _ => _t('Другое', 'Other', 'Boshqa'),
    };
  }

  String get waiveTitle => _t('Принять проверку с обоснованием', 'Accept the check with a reason', 'Tekshiruvni asos bilan qabul qilish');
  String get waiveKept => _t(
    'Исходная отметка проверки останется в карточке, а обоснование попадёт в журнал.',
    'The original mark of the check stays in the card and the reason goes to the log.',
    'Tekshiruvning dastlabki belgisi kartada qoladi, asos esa jurnalga yoziladi.',
  );
  String get waiveReasonLabel => _t('Основание', 'Basis', 'Asos');
  String get waiveCommentLabel => _t('Обоснование', 'Reason', 'Izoh');
  String get waiveCommentHint => _t('Что именно проверено и почему этого достаточно', 'What was checked and why it is enough', 'Nima tekshirilgani va nega bu yetarli');
  String get waiveCommentRequired => _t('Опишите обоснование: оно останется в журнале', 'Write the reason: it stays in the log', 'Asosni yozing: u jurnalda qoladi');
  String get waiveBlockWarning => _t(
    'Блок, принятый с обоснованием, отправляет транш на кредитный комитет.',
    'A block accepted with a reason sends the tranche to the credit committee.',
    'Asos bilan qabul qilingan blok transhni kredit qo‘mitasiga yuboradi.',
  );
  String get cancel => _t('Отмена', 'Cancel', 'Bekor qilish');
  String get waiveSubmit => _t('Записать решение', 'Record the decision', 'Qarorni yozish');
  String get saveFailed => _t('Не получилось сохранить. Попробуйте ещё раз.', 'Could not save. Please try again.', 'Saqlab bo‘lmadi. Qayta urinib ko‘ring.');

  // Decision.
  String get decisionClosed => _t('Решение сейчас недоступно: транш не на этапе специалиста.', 'The decision is not available now: the tranche is not at the specialist step.', 'Qaror hozir mavjud emas: transh mutaxassis bosqichida emas.');
  String get decisionSent => _t('Решение отправлено на согласование', 'The decision was sent for sign-off', 'Qaror kelishuvga yuborildi');
  String get openApproval => _t('Открыть маршрут согласования', 'Open the sign-off route', 'Kelishuv yo‘nalishini ochish');
  String get waitingBanner => _t('Транш у застройщика. Срок банка остановлен.', 'The tranche is with the developer. The bank clock is stopped.', 'Transh quruvchida. Bank muddati to‘xtatilgan.');
  String get pausedBanner => _t('Финансирование объекта приостановлено.', 'Financing of the project is paused.', 'Obyektni moliyalashtirish to‘xtatilgan.');
  String get rejectedBanner => _t('Транш отклонён банком.', 'The tranche was rejected by the bank.', 'Transh bank tomonidan rad etildi.');
  String get resume => _t('Вернуть в работу', 'Put back to work', 'Ishga qaytarish');
  String get partialConfirmTitle => _t('Отправить решение на согласование', 'Send the decision for sign-off', 'Qarorni kelishuvga yuborish');
  String partialConfirmBody(String issue, String returned) => _t(
    'К выплате $issue, на доработку $returned. Дальше решение уйдёт начальнику отдела.',
    'To pay out $issue, $returned goes back for rework. The decision then goes to the head of the department.',
    'To‘lash: $issue, qayta ishlashga: $returned. Keyin qaror bo‘lim boshlig‘iga yuboriladi.',
  );
  String get send => _t('Отправить', 'Send', 'Yuborish');
  String get reasonLabel => _t('Причина', 'Reason', 'Sabab');
  String get reasonRequired => _t('Опишите причину', 'Write the reason', 'Sababni yozing');
  String get returnAllTitle => _t('Вернуть застройщику целиком', 'Send it all back to the developer', 'Hammasini quruvchiga qaytarish');
  String get returnAllBody => _t(
    'Застройщик увидит причину. Срок банка остановится, пока он не ответит.',
    'The developer will see the reason. The bank clock stops until the developer answers.',
    'Quruvchi sababni ko‘radi. U javob bermaguncha bank muddati to‘xtaydi.',
  );
  String get measureTitle => _t('Заказать проверку на месте', 'Order a check on site', 'Joyida tekshiruvni buyurtma qilish');
  String get measureBody => _t(
    'Эксперт получит контрольный осмотр, транш уйдёт на этап осмотра.',
    'The expert gets a control inspection and the tranche goes back to the inspection step.',
    'Ekspert nazorat ko‘rigini oladi, transh ko‘rik bosqichiga qaytadi.',
  );
  String get suspendTitle => _t('Приостановить финансирование', 'Pause the financing', 'Moliyalashtirishni to‘xtatish');
  String get suspendBody => _t(
    'Выплаты по объекту остановятся, пока вы не вернёте транш в работу.',
    'Payouts for the project stop until you put the tranche back to work.',
    'Siz transhni ishga qaytarmaguningizcha obyekt bo‘yicha to‘lovlar to‘xtaydi.',
  );

  // Approval.
  String approvalTitle(int no) => _t('Транш №$no · согласование', 'Tranche #$no · sign-off', 'Transh №$no · kelishuv');
  String get toCheck => _t('К проверке', 'To the review', 'Tekshiruvga');
  String get routeTitle => _t('Маршрут согласования', 'Sign-off route', 'Kelishuv yo‘nalishi');
  String stepTitle(String code) {
    return switch (code) {
      'expert' => _t('Технический эксперт', 'Technical expert', 'Texnik ekspert'),
      'specialist' => _t('Кредитный специалист', 'Credit specialist', 'Kredit mutaxassisi'),
      'head' => _t('Начальник отдела', 'Head of the department', 'Bo‘lim boshlig‘i'),
      'committee' => _t('Кредитный комитет', 'Credit committee', 'Kredit qo‘mitasi'),
      'sign' => _t('Подпись ЭЦП (E-IMZO)', 'Digital signature (E-IMZO)', 'EHI imzosi (E-IMZO)'),
      'payment' => _t('Платёж', 'Payment', 'To‘lov'),
      _ => code,
    };
  }

  String stepStatus(String status) {
    return switch (status) {
      'done' => _t('Готово', 'Done', 'Tayyor'),
      'current' => _t('Сейчас', 'Now', 'Hozir'),
      'skipped' => _t('Не требуется', 'Not needed', 'Talab qilinmaydi'),
      'waiting' => _t('Недоступно', 'Not available', 'Mavjud emas'),
      _ => _t('Ждёт', 'Waiting', 'Kutmoqda'),
    };
  }

  String expertSigned(String date) => _t('Заключение по осмотру $date подписано', 'The inspection conclusion of $date is signed', '$date dagi ko‘rik xulosasi imzolangan');
  String specialistPrepared(String issue, int waived) => _t(
    'Подготовил решение: $issue, принято с обоснованием: $waived',
    'Prepared the decision: $issue, accepted with a reason: $waived',
    'Qarorni tayyorladi: $issue, asos bilan qabul qilingan: $waived',
  );
  String groupNeeds(int size, int required) => _t(
    'Группа из $size ${_people(size)} · нужно $required ${_approvals(required)}',
    'Group of $size · $required ${required == 1 ? 'approval' : 'approvals'} needed',
    '$size kishilik guruh · $required ta kelishuv kerak',
  );
  String _people(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'человека';
    return 'человек';
  }

  String _approvals(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'согласие';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'согласия';
    return 'согласий';
  }

  String get preparerCannot => _t('Тот, кто готовил решение, согласовать его не может', 'The person who prepared the decision cannot approve it', 'Qarorni tayyorlagan shaxs uni kelishib bera olmaydi');
  String committeeSkipped(String issue, String threshold) => _t(
    'Сумма $issue меньше порога $threshold, блоков с обоснованием нет',
    'The amount $issue is below the threshold $threshold and no blocks were accepted with a reason',
    '$issue summasi $threshold chegarasidan kam, asos bilan qabul qilingan blok yo‘q',
  );
  String committeeWhy(String reason, String threshold) {
    return switch (reason) {
      'waived_block' => _t('Есть блок, принятый с обоснованием', 'A block was accepted with a reason', 'Asos bilan qabul qilingan blok bor'),
      'amount_over' => _t('Сумма выше порога $threshold', 'The amount is above the threshold $threshold', 'Summa $threshold chegarasidan yuqori'),
      _ => '',
    };
  }

  String committeeLeave(int available, List<String> names) => _t(
    'Доступно $available, в отпуске: ${names.join(', ')}',
    '$available available, on leave: ${names.join(', ')}',
    'Mavjud: $available, ta’tilda: ${names.join(', ')}',
  );
  String votesCount(int approved, int required) => _t('Согласий: $approved из $required', 'Approvals: $approved of $required', 'Kelishuvlar: $approved / $required');
  String get signLocked => _t('Доступна только после всех согласований', 'Only available after all approvals', 'Faqat barcha kelishuvlardan keyin mavjud');
  String get paymentNote => _t(
    'Платёжные поручения создаёт АБС; iBuild обновляет «выдано» по каждой статье',
    'Payment orders are created by the banking system; iBuild updates “paid” for each item',
    'To‘lov topshiriqlarini ABT yaratadi; iBuild har bir modda bo‘yicha “to‘langan”ni yangilaydi',
  );
  String get cardTitle => _t('Карточка решения', 'Decision card', 'Qaror kartasi');
  String get cardIssue => _t('К выплате', 'To pay out', 'To‘lash uchun');
  String get cardReturned => _t('На доработку', 'For rework', 'Qayta ishlashga');
  String get cardWaived => _t('Принято с обоснованием', 'Accepted with a reason', 'Asos bilan qabul qilingan');
  String get returnLinesTitle => _t('Уходит застройщику на доработку', 'Goes back to the developer for rework', 'Quruvchiga qayta ishlashga qaytadi');
  String returnDeadline(int days) => _t('Срок на доработку: $days рабочих дней', 'Time for rework: $days working days', 'Qayta ishlash muddati: $days ish kuni');
  String get noReturnLines => _t('Ничего не возвращается', 'Nothing goes back', 'Hech narsa qaytmaydi');
  String get approve => _t('Согласовать', 'Approve', 'Kelishish');
  String get returnToSpecialist => _t('Вернуть специалисту', 'Return to the specialist', 'Mutaxassisga qaytarish');
  String get reject => _t('Отклонить', 'Reject', 'Rad etish');
  String get rejectTitle => _t('Отклонить транш', 'Reject the tranche', 'Transhni rad etish');
  String blocker(String code) {
    return switch (code) {
      'not_member' => _t('Вы не входите в группу, которая согласует этот шаг', 'You are not in the group that approves this step', 'Siz bu bosqichni kelishadigan guruhga kirmaysiz'),
      'on_leave' => _t('Вы в отпуске и не участвуете в согласовании', 'You are on leave and do not take part in the sign-off', 'Siz ta’tildasiz va kelishuvda qatnashmaysiz'),
      'preparer' => preparerCannot,
      'voted' => _t('Вы уже проголосовали', 'You have already voted', 'Siz allaqachon ovoz berdingiz'),
      'external' => _t('Следующий шаг выполняется во внешней системе', 'The next step is done in an external system', 'Keyingi bosqich tashqi tizimda bajariladi'),
      'closed' => _t('Транш закрыт', 'The tranche is closed', 'Transh yopilgan'),
      _ => _t('Транш сейчас не на согласовании', 'The tranche is not at sign-off now', 'Transh hozir kelishuvda emas'),
    };
  }

  String voteLabel(String vote) {
    return switch (vote) {
      'return' => _t('вернул специалисту', 'returned to the specialist', 'mutaxassisga qaytardi'),
      'reject' => _t('отклонил', 'rejected', 'rad etdi'),
      _ => _t('согласовал', 'approved', 'kelishdi'),
    };
  }
}
