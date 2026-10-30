part of 'l10n.dart';

/// Text for the read-only demo: the role buttons on the sign-in page and the strip on top.
extension DemoCopy on AppCopy {
  String get demoTitle => _t(('Посмотреть демо', 'Try the demo', 'Demoni koʻrish'));
  String get demoHint => _t((
    'Войдите без пароля и посмотрите, как всё устроено. Данные учебные, ничего не сохраняется.',
    'Sign in without a password and see how it works. The data is for practice and nothing is saved.',
    'Parolsiz kiring va hammasi qanday ishlashini koʻring. Maʼlumotlar oʻquv uchun, hech narsa saqlanmaydi.',
  ));
  String get demoBanner => _t((
    'Демо: данные учебные, изменения не сохраняются',
    'Demo: practice data, changes are not saved',
    'Demo: oʻquv maʼlumotlari, oʻzgarishlar saqlanmaydi',
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
