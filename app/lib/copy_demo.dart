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
    'bank' => _t(('Банк', 'Bank', 'Bank')),
    'admin' => _t(('Админ платформы', 'Platform admin', 'Platforma admini')),
    _ => role,
  };
}
