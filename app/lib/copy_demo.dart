part of 'l10n.dart';

/// Text for the read-only demo: the role buttons on the sign-in page and the strip on top.
extension DemoCopy on AppCopy {
  String get demoTitle => _t((
    'Демонстрационный кабинет',
    'Demo workspace',
    'Namoyish kabineti',
  ));
  String get demoHint => _t((
    'Выберите роль. В кабинете доступны примеры объектов и траншей для просмотра.',
    'Choose a role to view sample projects and tranches.',
    'Namunaviy obyektlar va transhlarni ko‘rish uchun rolni tanlang.',
  ));
  String get demoBanner => _t((
    'Демо · Только просмотр',
    'Demo · View only',
    'Demo · Faqat ko‘rish',
  ));
  String get demoExit => _t(('Выйти из демо', 'Leave demo', 'Demodan chiqish'));

  String demoRole(String role) => switch (role) {
    'developer' => _t(('Застройщик', 'Developer', 'Quruvchi')),
    'contractor' => _t(('Подрядчик', 'Contractor', 'Pudratchi')),
    'tech' => _t(('Технадзор', 'Technical supervisor', 'Texnik nazorat')),
    'bank' => _t(('Кредитный специалист', 'Credit specialist', 'Kredit mutaxassisi')),
    'bank_expert' => _t(('Технический эксперт', 'Technical expert', 'Texnik ekspert')),
    'bank_head' => _t(('Начальник отдела', 'Head of department', 'Bo‘lim boshlig‘i')),
    'bank_committee' => _t(('Кредитный комитет', 'Credit committee', 'Kredit qo‘mitasi')),
    'bank_risk' => _t(('Риск-менеджер', 'Risk manager', 'Risk-menejer')),
    'bank_admin' => _t(('Администратор банка', 'Bank administrator', 'Bank administratori')),
    'admin' => _t(('Админ платформы', 'Platform admin', 'Platforma admini')),
    _ => role,
  };

  String demoGroup(String group) => switch (group) {
    'developer' => _t(('Сторона застройщика', 'Developer side', 'Quruvchi tomoni')),
    'bank' => _t(('Банк', 'Bank', 'Bank')),
    _ => _t(('Платформа', 'Platform', 'Platforma')),
  };
}
